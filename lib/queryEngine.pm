use Storable;
use ir;
use strict;
use Data::Dumper;
use LWP::Simple;

use lib "./";

use POSIX qw "ceil floor"; #we would need the ceiling function for paginations

my $pageIndexHash = retrieve("pages.dex"); #get the document-level index with weighted words/vectors
my %pageIndex = %$pageIndexHash; #lay out the red carpet for the royal index - here comes the queen
   
my $idfIndexHash = retrieve("idf.dex");
my %idfIndex = %$idfIndexHash;

sub executeQuery {
   #receive the query as a preprocessed list of tokens - return a list of relevant ranked documents
   #receives a boolean as second argument to determine whether or not to use the intelligent component of search
   my $query = shift;
   my @queryTokens = @$query; #de-reference to get the actual list of tokens
   
   my $useIntelligent = shift; #boolean flag indicating whether to use intelligent component or not
   #print $useIntelligent . "\n";  
   my $synonymsRef = shift; 
   my @synonyms = @$synonymsRef;  #I need this in global scope
   if ($useIntelligent == 1){
      
      #second layer of intelligence - word emphasis   
      if (scalar(@queryTokens) > 1){
         #identify words in the query that need emphasis - only do this when the query has more than one term
         my $emphasisWords = emphasizeWords(\@queryTokens);
         my @emphasizedWords = @$emphasisWords;
         push(@queryTokens, @emphasizedWords);
      }
      
      push(@queryTokens, @synonyms); #add the synonyms only after words have been emphasized so that synonyms don't get emphasized too
      #print join(" ", @queryTokens);
   }
   
   my $pageNumber = shift;
   $pageNumber = $pageNumber - 1; #for technical reasons :), pageNumber has to start from zero
   
   #print Dumper(\@queryTokens);
   
   #create a tf-idf (normalized by max tf) weighted vector for the query
   my %queryVector = ();
   my %queryTerms = (); #unique terms in the query with their term frequencies
   my $maxTf = getMaxTf(\@queryTokens);
   
   my $numberOfDocs = scalar(keys %pageIndex);
   my %relevantDocs = (); #holds links (ids) of relevant documents
   
   #print "Query tokens\n";
   #print Dumper(\@queryTokens);
   
   #get the tfs for the tersm in the query
   
   foreach my $token (@queryTokens){
      $queryTerms{$token}++;
   }
   
   foreach my $token (@queryTokens){
      if (exists($idfIndex{$token})){ #essentially ignore words that do not appear in the collection
         #print "Adding word $token\n";    
         my $idf = $idfIndex{$token} + 0.5; #smoothing factor - 0.5
         my $tfidf = ($queryTerms{$token} * $idf) / $maxTf;  #normalized by maximum tf
         $queryVector{$token} = $tfidf; 
      
         my @documentids = (); #list of relevant documents - may contain duplicates
         foreach my $document (keys %pageIndex){
            if (exists($pageIndex{$document}{$token})){
               push (@documentids, $document);
            }
         }
         #compile the list of relevant documents - documents that contain at least one of the words in the query
         foreach my $documentid (@documentids){
            $relevantDocs{$documentid}++; #unique list of relevant document ids - no more duplicate page links
         }
      }
   }
   
   #if user is searching with intelligent option, the weight of added synonyms has to be diminished to reduce noise
   if ($useIntelligent == 1){
      foreach my $synonym (@synonyms){
         if (exists($queryVector{$synonym})){
            $queryVector{$synonym} = $queryVector{$synonym} / 3; #re-weighted synonyms
         }
      }
   }
   
   #print Dumper(\%queryVector); exit;
   
   my %cosineSimilarities = ();
   #calculate cosine similarity between each relevant document and query
   foreach my $relevantDocLink (keys %relevantDocs){
      #get the weighted tf-idf vector for this document
      my $docVectorHash = $pageIndex{$relevantDocLink};
      my %docVector = %$docVectorHash;
      
      #calculate the dot product of this document and the query
      my $dotProduct = calculateDotProduct(\%docVector, \%queryVector);
      #print "Dot product is $dotProduct\n";
      my $euclideanProduct = euclideanDistance(\%docVector) * euclideanDistance(\%queryVector);
      
      my $cosSimilarity = $dotProduct / $euclideanProduct;
      $cosineSimilarities{$relevantDocLink} = $cosSimilarity;
   }  
   
   #rank the search results in order of decreasing cosine similarity
   my @rankedPageResults = sort {$cosineSimilarities{$b} <=> $cosineSimilarities{$a}} keys %cosineSimilarities;

   #implement pagination of the search results
   my $numberPerPage = 10; #show ten(10) search results per page   
   my $totalResults = scalar(@rankedPageResults); #total number of search results found
   my $numberOfPages = $totalResults / $numberPerPage;
   if ($numberOfPages < 1){   
      $numberOfPages = ceil($numberOfPages);
   } else {
      $numberOfPages = floor($numberOfPages);
   }
   
   my $offset;
   if ($pageNumber+1 > $numberOfPages){
      #user somehow supplied a page number that does not exist
      $offset = 0;
      $pageNumber = 0;
   } else {
      $offset = $pageNumber * $numberPerPage;
   }
   
   my @resultsPage;
   if ($offset+($numberPerPage-1) <= $totalResults-1){ #prevent accessing outside the bounds of the list
      @resultsPage = @rankedPageResults[$offset..($offset+($numberPerPage-1))];
   } else {
      @resultsPage = @rankedPageResults[$offset..($offset+($totalResults-$offset-1))];   
   }
   
   my @results = (\@resultsPage, $totalResults, $numberOfPages);
   return @results;
   #return \@rankedPageResults;
}

sub getSynonyms {
   my $queryRef = shift;
   my @queryTokens = @$queryRef; #list of tokens in the original query
   
   #make an api request for synonyms of each word in the list of original query tokens
   my %synonyms = (); #this would be a list of synonyms for each word in the query
   my @rawSynonyms = (); #may contain duplicates
   for my $word (@queryTokens){
      #make request to BigHugeLabs synonyms api
      my $apikey = "77bdf98e4ae31598ea29226d82b89ca1";
      my $url = "http://words.bighugelabs.com/api/2/$apikey/$word/";
      my $contents = get($url); #this actually makes a get request to the synonyms api
      if (defined $contents){
         
         my @contentlist = split("\n", $contents);
         
         if (scalar(@contentlist) == 0){ #if for some weird reason, the api returns no words
            return \@rawSynonyms;
         }
         
         foreach my $data (@contentlist){
            my @datalist = split(/\|/, $data); #data is in the form "noun|syn|[word]" - split on |
            if ($datalist[1] eq "syn"){ #only grab synonyms
               #add to the list of synonyms gathered
               push(@rawSynonyms, $datalist[2]);
            }
         }
      }
   }
   
   #remove duplicate synonyms
   foreach my $synonym (@rawSynonyms){
      $synonyms{$synonym}++;
      
   }
   
   my @synonymList = keys %synonyms;
   return \@synonymList;
}

sub emphasizeWords {
   #lays emphasis on top two important words, that is, words with low document frequencies
   my $queryRef = shift;
   my @queryTokens = @$queryRef; #list of tokens in the original query 
   my @emphasizedWords = ();
   
   #get the document frequency for each word
   my %idfs = ();
   foreach my $token (@queryTokens){
      if (exists($idfIndex{$token})){ 
         #word is in the collection, so get the document frequency/idf of the token/word
         $idfs{$token} = $idfIndex{$token};         
      }
   }
   
   #sort the tokens in ascending order of document frequencies
   my @sortedTokens = sort {$idfs{$b} <=> $idfs{$a}} keys %idfs;
   
   if (scalar(@sortedTokens) != 0){ #actually found the words in the collection
      #two additions of word with least document frequency  
      push(@emphasizedWords, $sortedTokens[0]);
      push(@emphasizedWords, $sortedTokens[0]);
   
      #one addition of word with next least document frequency
      push(@emphasizedWords, $sortedTokens[1]);
      
   }
   
   return \@emphasizedWords;
}

1;