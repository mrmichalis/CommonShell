#!/usr/bin/perl -w
use strict;
use XML::Twig;
use LWP;

# my $url	= 'http://sftp.uk3.ribob01.net:8080/publish-notification/zabbixThreadMonitor.jsp';
# my $twig 	= XML::Twig->parse( TwigHandlers => { 'thread[string(isRunning)="true"]' => \&process}, $url);

my $twig= new XML::Twig( TwigHandlers => { 'thread[string(isRunning)="false"]' => \&process });  
$twig->parsefile( "test.xml");

sub process
{
	my ($twig, $element) = @_;
	#print $element->name,"\n";
	foreach my $child ($element->children)
	{
		if ($child->name !~ m/last/)
		{
			print $element->parent->name," ",$child->name,": ",$child->text," ";
		}
	}
	print "\n";
}