#!/usr/bin/perl

print "Content-type: text/html\n\n";
 
use warnings;
use strict;
use Data::Dumper;
use Storable;
use CGI;

$|++;

use lib "./lib";
use ir;
use queryEngine;
use porter;

my $interface = new CGI;
#my $query = "computer science and engineering";
my $query = $interface->param('querystr');
$query = lc($query); #make sure query is in lowercase
#my $useIntelligent = 0;
my $useIntelligent = $interface->param('intelligent');

$query = prepForTokenization($query);
my @tokenizedQuery = tokenizeText($query); #split the query into tokens
my @synonyms = (); #synonyms for query expansion

if ($useIntelligent == 1){
   #remove stopwords and get synonyms
   my $tokenizedQueryRef = cleanDocument(\@tokenizedQuery, 0); #remove stopwords and punctuations, but don't stem
   my @tokenizedQuery = @$tokenizedQueryRef;
   my $synonymsRef = getSynonyms(\@tokenizedQuery);
   my @unstemmedSyn = @$synonymsRef; #unstemmed synonyms

   #stem the synonyms
   
   foreach my $synonym (@unstemmedSyn){
      push(@synonyms, porter($synonym));
   }
     
}

#get all the page titles
my $pageTitleRef = retrieve('titles.dex');
my %pageTitles = %$pageTitleRef;

#clean the query again - remove stopwords, punctuations and do stemming - the query this time might contain synonyms
my $cleanQueryRef = cleanDocument(\@tokenizedQuery, 1); #returns a reference to the "cleaned" query, does stemming
my @cleanedQuery = @$cleanQueryRef;

#my $pageNumber = 1;
my $pageNumber = $interface->param('page');
my @queryResults = executeQuery(\@cleanedQuery, $useIntelligent, \@synonyms, $pageNumber); #last two parameters are "intelligence" and "page number" 
my $totalResults = $queryResults[1];
my $numberOfPages = $queryResults[2];
my $searchResults = $queryResults[0];
my @searchResultsList = @$searchResults; #this is a list of links deemed to be relevant to the query

#print Dumper(\@searchResultsList);

displayResults();

sub displayResults {
	$query =~ s/^\s*(.*?)\s*$/$1/;
	
	print <<TOP;
	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
	<html>
	<head>
		<meta name="description" content="" />
		<meta name="keywords" content="" />
		<meta name="author" content="David Adamo Jr" />
		<meta http-equiv="content-type" content="text/html;charset=UTF-8" />
		<title>TinySearch | Search Results</title>
		<link rel="stylesheet" type="text/css" href="css/style.css" />
		<link rel="stylesheet" type="text/css" href="css/typography.css" />
		<link rel="stylesheet" type="text/css" href="css/buttons.css" />
		<style type="text/css">
			.pagination li a {
				border-bottom: 1px solid #cccccc;
			}
		</style>
		<script src="js/jquery-1.7.1.min.js" type="text/javascript"></script>
		<script type="text/javascript">
			jQuery(document).ready(function(){
				jQuery('#basic').click(function(){
					if (jQuery('#search_input').val() == ''){
						jQuery('#search_input').val('');
					} else {
						jQuery('input[name=intelligent]').val('0');
			            jQuery('#searchform').submit();
   					}
				});
		  
				jQuery('#intelligent').click(function(){
					if (jQuery('#search_input').val() == ''){
						jQuery('#search_input').val('');
					} else {
						jQuery('input[name=intelligent]').val('1');
			            jQuery('#searchform').submit();
					}
				});
			});
		</script>
	</head>
	<body>
		<div class="header-content" style="">
			<div class="searchbar" style="">
				<div class="mainleft" style="">
					<a href="index.html"><img src="images/logotext.png" alt="TinySearch" style="padding:10px 0 0 5px;" /></a>
				</div>
				<div class="maindiv" style="">
					<form id="searchform" style="float:left;" action="searchresults.cgi">
						<input id="search_input" name="querystr" placeholder="Enter a query" type="text" value="$query"/>
						&nbsp;&nbsp;&nbsp;
						<input type="button" id="basic" class="btn" value="Basic Search" />&nbsp;&nbsp;<input id="intelligent" type="button" class="btn" value="Intelligent Search" />
						<input type="hidden" name="intelligent" value="0" />
						<input type="hidden" name="page" value="1" />
					</form>
				</div>
				<br class="clear" />
			</div>
		</div>
		<div class="main-wrapper" style="">
			<div class="inner-wrapper">
				<div class="main-content" style="">
					<div class="searchtop">
						<div class="mainleft">
							<h4 style="color:#974578;">Search Results</h4>
						</div>
						<div class="maindiv" style="width:710px;color:#999999;">
							<p class="searchtitle">Page <span id="pagemarker">$pageNumber</span> of <span id="resultcount">$totalResults</span> results</p>
						</div>
						<br class="clear"/>
					</div>
					<div class="mainleft">
						<div class="pagelinks" style="margin-bottom: 30px;background-color:#f6f6f6;padding:5px;">
							<p><b>Tip:</b> Using <i>intelligent search</i> might provide better search results for your query.</p>
						</div>
					</div>
					<div class="maindiv" style="width:710px;padding:0;">
						<div class="result_listing" style="">
							<div class="pageset">
TOP
	if (scalar(@searchResultsList) > 0){
		foreach my $searchResult (@searchResultsList){
		  if (defined $pageTitles{$searchResult}){
			 print <<LISTING;
			 <div class="search_listing" style="">
				<div class="staff_detail">
					<h4><a href="$searchResult" target="_blank">$pageTitles{$searchResult}</a></h4>
				</div>
				<div class="staff_detail">
					$searchResult
				</div>
			</div>
LISTING
		  } else {
			 print <<LISTING2;
			 <div class="search_listing" style="">
				<div class="staff_detail">
					<h4><a href="$searchResult" target="_blank">Untitled Page</a></h4>
				</div>
				<div class="staff_detail">
					$searchResult
				</div>
			</div>
LISTING2
		  }
		}

		print "<div class='pagination' style='padding-top:80px;'><ul><li class='prev disabled'><a href='#'>Pages</a></li>";
		if ($numberOfPages < 15){
		   foreach my $page ((1..$numberOfPages)){
			  print "<li><a href='searchresults.cgi?page=$page&intelligent=$useIntelligent&querystr=$query'>$page</a></li>";
		   }
		} else {
		   foreach my $page ((1..15)){
			  print "<li><a href='searchresults.cgi?page=$page&intelligent=$useIntelligent&querystr=$query'>$page</a></li>";
		   }
		}
		print "</ul></div></div>";
	} else {
		print "<b>No results found.</b>";
	}
	print "</div><br class='clear' /></div><br class='clear' /></div>";
	print <<FOOTER;
		<div class="footer">
			<div class="copyright">
				<div>Thanks to <i><a href="http://words.bighugelabs.com/api.php" target="_blank">BigHugeLabs</a></i> for their thesaurus API<br/>
					Thanks to Dr. Rada Milhacea for her excellent tutelage<br/>David Adamo Jr.</div>
				</div>
				<br class="clear" />
			</div>
		</div>
	</body>
	</html>
FOOTER
	
}
