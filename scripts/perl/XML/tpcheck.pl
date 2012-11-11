#!/usr/bin/perl -w
# $Id: tpcheck.pl,v .8 2012/11/09 16:37:50 michalis Exp michalis $

use strict;
use XML::Twig;
use LWP;

my $logfile = "./mylogfile.log"; # log file location
my $out_message = ""; 			 # init log message
# the URL for the xml to parse
my $url		= 'http://sftp.uk3.ribob01.net:8080/publish-notification/zabbixThreadMonitor.jsp';
my $twig 	= XML::Twig->parse( TwigHandlers => { 'thread[string(isRunning)="true"]' => \&process}, $url);

# local
# my $twig 	= new XML::Twig( TwigHandlers => { 'thread[string(isRunning)="false"]' => \&process });  
# $twig->parsefile( "test.xml");

# process xml file
sub process {
	my ($twig, $element) = @_;
	#print $element->name,"\n";
	foreach my $child ($element->children)
	{
		if ($child->name !~ /last/)
		{
			$out_message .= "\t".$child->name.": ".$child->text."\t";
		}
	}
	&log ($element->parent->name." $out_message\n");
	undef $out_message;
}

# write to a log file
sub log {
	my $message = shift;
    	my $now     = localtime;
	my $logmsg 	= "$now ERROR\t$message";
	open LOGFILE, ">>$logfile" or die "cannot open logfile $logfile for append: $!";
	print LOGFILE $logmsg;
	close LOGFILE;
}