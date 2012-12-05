#!/usr/bin/perl -w
# $Id: tpcheck.pl,v .8 2012/11/09 16:37:50 michalis Exp michalis $

use strict;
use XML::Twig;
use LWP::Simple; 
 
# the URL for the xml to parse
my $url 		= 'http://pwspp.uk3.ribob01.net:8080/publish-notification/zabbixThreadMonitor.jsp';

# Tidy up the XML contents by removing all blank spaces and new lines
my $url_content = get($url);
$url_content 	=~ s/^\s*\n+//mg;

my $logfile 	= "mylogfile.log"; 		# log file location
my $out_message = ""; 			 	# init log message
my $threads		= XML::Twig->parse( TwigHandlers => { 'thread[string(isRunning)="true"]' => \&process_tp}, $url_content);
my $ingestdiff	= XML::Twig->parse( TwigHandlers => { 'ingestMonitor' => \&process_ingest}, $url_content);

# local
# my $threads 	= new XML::Twig( TwigHandlers => { 'thread[string(isRunning)="false"]' => \&process });  
# $threads->parsefile( "test.xml");

sub process_ingest 
{
	my ($ingestdiff, $element) 	= @_;
	my $sent 					= get_el_text('sent', $element);
	my $received 				= get_el_text('received', $element);
	my $diff 					= get_el_text('diff', $element);

	print "sent: ", $sent, "\n";
	print "received: ", $received,"\n";
	print "diff: ", $diff,"\n";
	print parse_secs(abs($diff/1000))."\n";	
}

# process xml file
sub process_tp 
{
	my ($threads, $element) = @_;
	#print $element->name,"\n";
	foreach my $child ($element->children)
	{
		$out_message .= "\t".$child->name.": ".$child->text."\t" if ($child->name !~ /last/);
	}
	&log ($element->parent->name." $out_message\n");
	undef $out_message;
}

# Get Child Text from Element
sub get_el_text
{	
	my ($name, $element) = @_;
	my @elm 	= $element->children($name);
	foreach my $elm (@elm)
	{ return $elm->text; }
}

sub parse_secs 
{
    my $secs = shift;
    if    ($secs >= 365*24*60*60) { return sprintf '%.1fy', $secs/(365*24*60*60) }
    elsif ($secs >=     24*60*60) { return sprintf '%.1fd', $secs/(    24*60*60) }
    elsif ($secs >=        60*60) { return sprintf '%.1fh', $secs/(       60*60) }
    elsif ($secs >=           60) { return sprintf '%.1fm', $secs/(          60) }
    else                          { return sprintf '%.1fs', $secs                }
}

# write to a log file
sub log 
{
	my $message = shift;
    my $now     = localtime;
	my $logmsg 	= "$now ERROR\t$message";
	open LOGFILE, ">>$logfile" or die "cannot open logfile $logfile for append: $!";
	print LOGFILE $logmsg;
	close LOGFILE;
}