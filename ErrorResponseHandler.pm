package ErrorResponseHandler; 

use strict;
use warnings;
use Data::Dumper;
use File::Slurp qw(write_file append_file);
use Apache2::Const -compile => qw(OK);

$Data::Dumper::Sortkeys = 1;

sub handler {
	my $r = shift;
  
    $r->content_type('text/plain');
    $r->print( 'yes' );
 
    return Apache2::Const::OK;
}

1;
