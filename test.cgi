#!/usr/bin/perl -w

use X;
use CGI;
use strict;
#use CGI::Carp qw(fatalsToBrowser);

my $cgi = CGI->new();

my $header = $cgi->header();

if ( $header =~ /content-type:\s+?text\/html/i ) { 
use Data::Dumper; 
$Data::Dumper::Sortkeys = 1;
my $brian_custom = '/tmp/dumper.txt';
open my $fh, '>>', $brian_custom;
print $fh Dumper( $header );
close $fh;

}

my $buf = $cgi->header( -type => 'text/plain', -charset => 'UTF-8' );
$buf   .= 'hi there';

print $buf;
