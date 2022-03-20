package ErrorLogHandler;

=head2

	chmod a+x /var/log/apache2/ 
	chmod a+r /var/log/apache2/*

	Add www-data to adm.
	adm:x:4:syslog,lunab,www-data

=cut

use strict;
use warnings;
use DB::PgSimple;
use Data::Dumper;
use File::ReadBackwards;
use Apache2::Const -compile => qw(OK);
use File::Slurp qw(write_file append_file read_file);

$Data::Dumper::Sortkeys = 1;

use Apache2::RequestRec();
use Apache2::Connection();
use Apache2::RequestUtil();

my $db = DB::PgSimple->new();

sub handler {
	my $r = $_[0];

	my $c           = $r->connection();
	my $file_name   = $r->filename();
	my $methnum     = $r->method_number();
	my $status_line = $r->status_line();
	my $remote_host = $c->get_remote_host();

	my $data             = {};
	$data->{file}        = '/var/log/apache2/error.log';
	$data->{script_name} = $r->filename();
	$data->{status_line} = $r->status_line();
	$data->{remote_host} = $c->get_remote_host();

	# The error is found.
	my $found     = find_entries( data => $data );
	my $unique_id = $r->subprocess_env( 'UNIQUE_ID' );

	# Save into the db.
	# TODO throttle.
	if ( $found ) {
		$found = substr $found, 0, 2000;
		$db->write( sql => 'insert into logs (log, unique_id, created_tod) values(?, ?, current_timestamp)', values => [ $found, $unique_id ] );
		warn "Added UNIQUE_ID $unique_id";
	}

	return Apache2::Const::OK;
}

# Find.
sub find_entries { 
	my ( %args ) = @_;

	my $data = $args{data};

	my $bw = File::ReadBackwards->new( $data->{file} ) or die "can't read 'log_file' $!" ;

	my $max   = 2;
	my $count = 0;

	my $buf = '';

	while ( defined( my $log_line = $bw->readline ) ) {
		if ( $count <= $max && $log_line =~ /$data->{script_name}/ && $log_line =~ /$data->{remote_host}/ ) { 
			chomp $log_line;
			$buf .= $log_line;
			$count++;
		}
	}

	return $buf;
}

1;
