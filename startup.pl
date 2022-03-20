#!/usr/bin/perl -w 

use strict;
use CGI ();
CGI->compile(':all');

# Un-comment if wish to log to apache.
#use CGI::Carp qw(fatalsToBrowser);
#
#$SIG{__DIE__}  = \&Carp::cluck;
#$SIG{__WARN__} = \&Carp::cluck;
#
#warn "testing\n";

1; 
