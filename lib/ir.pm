#Author: David Adamo
#Student ID: 10816690

use porter;

sub prepForTokenization {
	my $document = shift;
	$document =~ tr/[ \t\r\n]//s; #remove unnecessary whitespace
	$document =~ s/^\s+//; #remove spaces at the beginning of the document

	#rectify issues with quotes
	$document =~ s/\'\' /\" /g;
	$document =~ s/ \`\`/ \"/g;
	$document =~ s/\'\'$/\"/g;
	$document =~ s/^\`\`/\"/g;

	#insert space after period that is followed by an alphabet and not another period
	$document =~ s/\.([^0-9\.])/\. $1/g;
	$document =~ s/\.$/\. /g;

	#put space after periods that are followed by another period or preceded by another period
	$document =~ s/([^\.])\.([ \.])/$1 \.$2/g;
	
	#insert spaces around commas except they are surrounded by numbers
	$document =~ s/([0-9,])\,([0-9,])/$1,$2/g;
	$document =~ s/\,/ \, /g;

	#insert spaces before punctuation symbols
	$document =~ s/([^ \!])(\!+)/$1 $2/g;
	$document =~ s/([^ \?])(\?+)/$1 $2/g;
	$document =~ s/([^ \;])(\;+)/$1 $2/g;
	$document =~ s/([^ \"])(\"+)/$1 $2/g;
	$document =~ s/([^ \)])(\)+)/$1 $2/g;
	$document =~ s/([^ \(])(\(+)/$1 $2/g;
	$document =~ s/([^ \/])(\/+)/$1 $2/g;
	$document =~ s/([^ \&])(\&+)/$1 $2/g;
	$document =~ s/([^ \^])(\^+)/$1 $2/g;
	$document =~ s/([^ \%])(\%+)/$1 $2/g;
	$document =~ s/([^ \$])(\$+)/$1 $2/g;
	$document =~ s/([^ \+])(\++)/$1 $2/g;
	$document =~ s/([^ \-])(\-+)/$1 $2/g;
	$document =~ s/([^ \#])(\#+)/$1 $2/g;
	$document =~ s/([^ \*])(\*+)/$1 $2/g;
	$document =~ s/([^ \[])(\[+)/$1 $2/g;
	$document =~ s/([^ \]])(\]+)/$1 $2/g;
	$document =~ s/([^ \{])(\{+)/$1 $2/g;
	$document =~ s/([^ \}])(\}+)/$1 $2/g;
	$document =~ s/([^ \>])(\>+)/$1 $2/g;
	$document =~ s/([^ \<])(\<+)/$1 $2/g;
	$document =~ s/([^ \_])(\_+)/$1 $2/g;
	$document =~ s/([^ \\])(\\+)/$1 $2/g;
	$document =~ s/([^ \|])(\|+)/$1 $2/g;
	$document =~ s/([^ \=])(\=+)/$1 $2/g;
	$document =~ s/([^ \'])(\'+)/$1 $2/g;
	$document =~ s/([^ \`])(\`+)/$1 $2/g;

	#insert space after punctuation symbols
	$document =~ s/(\!+)([^ \!])/$1 $2/g;
	$document =~ s/(\?+)([^ \?])/$1 $2/g;
	$document =~ s/(\;+)([^ \;])/$1 $2/g;
	$document =~ s/(\"+)([^ \"])/$1 $2/g;
	$document =~ s/(\(+)([^ \(])/$1 $2/g;
	$document =~ s/(\)+)([^ \)])/$1 $2/g;
	$document =~ s/(\/+)([^ \/])/$1 $2/g;
	$document =~ s/(\&+)([^ \&])/$1 $2/g;
	$document =~ s/(\^+)([^ \^])/$1 $2/g;
	$document =~ s/(\%+)([^ \%])/$1 $2/g;
	$document =~ s/(\$+)([^ \$])/$1 $2/g;
	$document =~ s/(\++)([^ \+])/$1 $2/g;
	$document =~ s/(\-+)([^ \-])/$1 $2/g;
	$document =~ s/(\#+)([^ \#])/$1 $2/g;
	$document =~ s/(\*+)([^ \*])/$1 $2/g;
	$document =~ s/(\[+)([^ \[])/$1 $2/g;
	$document =~ s/(\]+)([^ \]])/$1 $2/g;
	$document =~ s/(\}+)([^ \}])/$1 $2/g;
	$document =~ s/(\{+)([^ \{])/$1 $2/g;
	$document =~ s/(\\+)([^ \\])/$1 $2/g;
	$document =~ s/(\|+)([^ \|])/$1 $2/g;
	$document =~ s/(\_+)([^ \_])/$1 $2/g;
	$document =~ s/(\<+)([^ \<])/$1 $2/g;
	$document =~ s/(\>+)([^ \>])/$1 $2/g;
	$document =~ s/(\=+)([^ \=])/$1 $2/g;
	$document =~ s/(\`+)([^ \`])/$1 $2/g;
	
	#seperate words with just alphabets
	$document =~ s/([a-zA-Z]+)/ $1 /g;
	
	#deal with popular abbreviations
	$document =~ s/[\s\.]U\s+\.\s+S\s+\.\s+S\s+\.\s+R\s+\./U.S.S.R./g;
    $document =~ s/[\s\.]U\s+\.\s+S\s+\.\s+A\s+\./U.S.A./g;
    $document =~ s/[\s\.]P\s+\.\s+E\s+\.\s+I\s+\./P.E.I./g;
    $document =~ s/[\s\.]p\s+\.\s+m\s+\./p.m./g;
    $document =~ s/[\s\.]a\s+\.\s+m\s+\./a.m./g;
    $document =~ s/[\s\.]U\s+\.\s+S\s+\./U.S./g;
    $document =~ s/[\s\.]B\s+\.\s+C\s+\./B.C./g;
	$document =~ s/[\s\.]vol\s+\./vol./g;
	$document =~ s/[\s\.]etc\s+\./etc./g;
	$document =~ s/[\s\.]eg\s+\./eg./g;
	$document =~ s/[\s\.]i\s+\.\s+e\s+\./i.e./g;
	$document =~ s/[\s\.]e\s+\.\s+g\s+\./e.g./g;
	
	return $document;
}

sub tokenizeText {
	my $document = shift;
	@tokenizedDocument = split(/\s+/, $document);
	return @tokenizedDocument;
}

sub removeTags {
	#remove HTML/SGML tags from a document
	my $document = shift; #get the first an only argment from the @_ list
	$document =~ s/<.+?>//g;
	return $document;
}

sub cleanDocument {
   #this subroutine removes punctuations and stop words from documents and stems the tokens as well
   
   #list of stopwords to remove from the collection/queries
   my @stopwords = ('a','all','an','and','any','are','as','be','been','but','by','few','for','have','he','her','here','him','his',
                    'how','i','in','is','it','its','many','me','my','none','of','on','or','our','she','some','the','their','them','there','they',
                    'that','this','us','was','what','when','where','which','who','why','will','with','you','your','to','at','from','were', 'have','over',
                    'anyone','all','having','under','using','can','above');
   my @punctuations = ('.','[',']',':',',','!','?',';',')','(','/','&','^','%','$','+','-','#','*'); 
    
   #create a stopword hash from the list of stopwords that can be used for list membership tests
   my %stopwordhash = ();
   foreach my $stopword (@stopwords){
      $stopwordhash{$stopword} = 1;
   }
   
   #create a punctuation hash from the list of punctuations that can be used for list membership tests
   my %punchash = ();
   foreach my $punctuation (@punctuations){
      $punchash{$punctuation} = 1;
   }
   
   my $tokensRef = shift; #this subroutine receives a reference to the list of tokens as an argument
   my @tokenizedDoc = @$tokensRef;
   
   $doStemming = shift; #second argument is flag that indicates whether to carry out stemming is as well
   my @cleanedDocument = ();
   foreach my $token (@tokenizedDoc){
      $token =~ s/\s+//;
      if ($token eq ''){
         next; #ignore empty strings
      }
      
      if (!exists($punchash{$token}) && !exists($stopwordhash{$token})){
         if ($doStemming){
            push @cleanedDocument, porter($token);     
         } else {
            push @cleanedDocument, $token;
         }
      }
   }
   
   #return a reference to the @cleanedDocument list
   return \@cleanedDocument;                                 
}

sub getMaxTf {
   #this subroutine gets the maximum term frequency in a document
   #the list of document tokens is passed to this subroutine as an array reference
   my $docTokens = shift;
   my @listOfTokens = @$docTokens;
   
   #get the term frequencies for the document and place them in hash
   my %termFreqs = ();
  
   foreach my $term (@listOfTokens){
      $termFreqs{$term}++; 
   }
   
   my @sortedFreqs = sort {$b <=> $a} values(%termFreqs);
   
   return $sortedFreqs[0];

}

sub calculateDotProduct{
   #this subroutine calculates the dot product of two vectors
   
   my $firstVectorRef = shift;
   my $secondVectorRef = shift;
   
   my %firstVector = %$firstVectorRef;
   my %secondVector = %$secondVectorRef;
   
   $dotproduct = 0;
   foreach my $component (keys %firstVector){
      $dotproduct = $dotproduct + ($firstVector{$component} * $secondVector{$component});   
   }
   
   return $dotproduct;
}

sub euclideanDistance{
   #this subroutine calculates the Euclidean distance between two vectors
   my $vectorRef = shift; #the vector is passed to this subroutine as a an argument
   my %vector = %$vectorRef;
      
   $euclideanDistance = 0;
   foreach my $component (keys %vector){
      $euclideanDistance = $euclideanDistance + ($vector{$component} * $vector{$component});
   }
   $euclideanDistance = sqrt($euclideanDistance);
   
   return $euclideanDistance;
}       

sub cosineSimilarity{
   my $firstVectorRef = shift;
   my $secondVectorRef = shift;
   
   my $euclideanProduct = euclideanDistance($firstVectorRef) * euclideanDistance($secondVectorRef);
   my $cosSim = calculateDotProduct($firstVectorRef, $secondVectorRef) / $euclideanProduct;
   return $cosSim;
}

sub removeStopwords {
   
}
1;