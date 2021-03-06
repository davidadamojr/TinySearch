#Author: David Adamo

#This set of subroutines gathers 3000 links from the UNT domain

#catch all problems in the code
use warnings;

use LWP::Simple;
use LWP::UserAgent;
use URI::URL;
use HTML::LinkExtor;
use Storable;

my @linkqueue = ("http://www.cse.unt.edu/site/index.php","http://www.unt.edu/");
my %linksfound = (); #links gathered so far
#$linksfound{$linkqueue[0]}++; #add unt edu to the links found hash

my %alreadycrawled = (); #links already opened previously
my $linkcount = 0;
my $numberToCrawl = 6000;

sub gatherLinks {
   #start the process of gathering links
  while (scalar(keys %linksfound) < $numberToCrawl){
      my $pageurl = pop @linkqueue;
      my $urlObject = url($pageurl);
      my $baseurl = $urlObject->scheme . "://" . $urlObject->host;
      my $useragent = LWP::UserAgent->new;
      my $linkextractor = HTML::LinkExtor->new(\&callback, $baseurl);
      $useragent->request(HTTP::Request->new(GET => $pageurl), sub {$linkextractor->parse($_[0])});
      $alreadycrawled{$pageurl}++;
      #if (scalar(keys @linksfound) < 3000){
        # gatherLinks(); #recursive call to keep gathering links until we have up to 3000
      #}
   }     
}

#this callback is called for every page
sub callback {
   my ($tag, %attr) = @_;
   return if $tag ne 'a'; #we are only trying to gather links at this point... nothing else
   
   #link tag found, so continue
   #ensure duplicate lins are not allowed
   my $url = $attr{href};
   
   #remove anchors from urls
   $url =~ s/#.*$//;
   
   #remove trailing slashes from urls
   $url =~ s/\/$//;   
   
   if ($linkcount < $numberToCrawl && !exists($linksfound{$url}) && !exists($alreadycrawled{$url}) && isUntLink($url)){
      print $linkcount + 1 .  ": Adding $url ...\n";
      unshift(@linkqueue, $url);
      $linksfound{$url}++; #add the url found to the list
      $linkcount = $linkcount + 1;      
   }
}

sub isUntLink {
   #checks to ensure a links ia UNT link and is not a mailto link either
   
   #do not allow "mailto" links
   $_ = shift;
   if (m/^mailto/){
      return 0; #execution ends here in this case
   }
   
   if (m/^https/){ #https links often result in duplicates with their non-https counterparts
      return 0;
   }
   
   #do not allow map.unt.edu links
   if (m/maps.unt.edu/){
      return 0; #execution ends here
   }
   
   #do not allow images or pdf files
   if (m/\.jpg$/ || m/\.JPG$/ || m/\.jpeg$/ || m/\.gif$/ || m/\.GIF$/ || m/\.png$/ || m/\.pdf$/ || m/\.doc$/ || m/\.docx/ || m/\.mov/){
      return 0;
   }
   
   #execution continues up tot his point since it is not mailto, now test that it is on the UNT domain
   $fullurl = URI->new($_);
   $_ = $fullurl->host();
   if (m/unt.edu$/){
      return 1;
   } else {
      return 0;
   }
}

#sub getLinks {
   gatherLinks();
   #return \%linksfound;
#}

my @parseList = keys %linksfound;
store(\@parseList, "../links.dat");

1;
