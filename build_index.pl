#Author: David Adamo

use warnings;
use strict;

$|++;

#catch all possible problems in the code
use lib "./lib";

#use linkgatherer;
use ir;
use porter;

use Storable;

use LWP::Simple;
use LWP::UserAgent;

use Data::Dumper;

my $useragent = LWP::UserAgent->new;
$useragent->timeout(10);
$useragent->env_proxy;

#my $linksToParse = getLinks();

my $parseListRef = retrieve('links.dat');
my @parseList = @$parseListRef;

#my @parseList = ("http://www.unt.edu/", "http://www.cse.unt.edu/site/index.php");

my %wordIndex = (); #index for word, document and term frequencies
my %titlesIndex = (); #index for links and page titles
my %pageIndex = (); #document-level index for easy creation of vectors
my %idfIndex = ();

my %maxTermFreqs = ();

my $numberOfLinks = 0;
my $index = 0;
my $link;
#while ($link = pop @parseList){
foreach my $link (@parseList){
   #open the link
   #my $pagedata = get($link);
   my $response = $useragent->get($link);
   if ($response->is_success){
      #page information gotten successfully
      print $numberOfLinks + 1 .  ": Indexing $link ...\n";
      
      $titlesIndex{$link} = $response->title(); #store the title for this link
      
      my $document = $response->content;
      $document = removeTags($document); #remove html tags from the document
      $document = prepForTokenization($document);
      my @tokenizedDocument = tokenizeText($document);
      
      #clean the document, remove stopwords, punctuations and stem
      my $cleanDocRef = cleanDocument(\@tokenizedDocument, 1); #1 is a flag that indicates stemming is needed
      my @cleanedDocument = @$cleanDocRef;
      
      #get the maximum term frequency in this document
      my $maxTermFreq = getMaxTf(\@cleanedDocument); #pass the document tokens as array references
      $maxTermFreqs{$link} = $maxTermFreq;
      
      #create a word-levelindex
      foreach my $token (@cleanedDocument){
         $token =~ s/^\s*(.*?)\s*$/$1/;
         $token = lc($token); #convert to lowercase;
         
         if ($token eq ""){
            next; #ignore tokens that are empty strings
         }
         
         if (exists($wordIndex{$token})){
            #this word has been encountered before, so get the word count (tf) for the current document
            if (exists($wordIndex{$token}{$link})){
               $wordIndex{$token}{$link}++;
            } else {
               $wordIndex{$token}{$link} = 1;
            }
         } else {
            #word does not already exist in the index, so create an entry for it
            $wordIndex{$token} = {$link => 1};
         }
         
         #create the document-level index as well
         $pageIndex{$link}{$token}++;
      }
      $numberOfLinks = $numberOfLinks + 1; #only count active and working links       
      
      #if ($numberOfLinks == 4000){
         #last; #end after successfully getting 3000 links that work
      #}
   } else {
      print $response->status_line, " for $link ... moving on.\n";
   }
   
   #after dealing with a link, "remove" the link from the parse list to possibly save memory
   undef $parseList[$index];
   $index = $index + 1;
}

my @words = keys %wordIndex;

foreach my $word (@words){
   my $documentshash = $wordIndex{$word}; #hash of documents that this word appears in
   my $documentfrequency = scalar(keys %$documentshash); #number of documents the word appears in
   my $idf = log($numberOfLinks/$documentfrequency) / log(10);
   
   #add the idf for this word to the idf index
   $idfIndex{$word} = $idf;
   
   #update the weighting of this word in every document
   foreach my $document (keys %pageIndex){
      if (exists($pageIndex{$document}{$word})){
        #FUTURE WORK: could use arguments to decide which weighting scheme to use and create multiple indexes for different schemes
      
        #the word is in this document, change its tf to its weighted tf normalized by max tf
        my $termfrequency = $pageIndex{$document}{$word};
        my $tfidf = ($termfrequency * $idf) / $maxTermFreqs{$document};
        #my $weight = 0.5 + (0.5 * $weight) / $maxTermFreqs{$document}; #best weighted probablistic
        my $docVectorHash = $pageIndex{$document};
        my %docVector = %$docVectorHash;
        #my $weight = $termfrequency / euclideanDistance(\%docVector); #standard tf weight scheme
        $pageIndex{$document}{$word} = $tfidf;
     }   
   }
}

print "Total number of links indexed is: $numberOfLinks";

#store the index files on disk

store(\%wordIndex, "words.dex"); #word-level inverted index
#store(\%pageIndex, "pages.dex"); #document-level inverted index
store(\%idfIndex, "idf.dex");
store(\%titlesIndex, "titles.dex"); #page titles


#print Dumper(\%wordIndex);

#print Dumper(\%pageIndex);

#print Dumper(\%titlesIndex);*/