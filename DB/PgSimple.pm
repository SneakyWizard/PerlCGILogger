package DB::PgSimple;

use strict;
use DBIx::Simple;

sub new { 
	return bless {}, $_[0];
}

sub connect {
	my ( $self, %args ) = @_;

	my $db_name = $args{db_name} || 'Logs';
	my $host    = $args{host}    || 'localhost';
	my $user    = $args{user}    || 'logs';
	my $pass    = $args{pass}    || 'Logs';

	my $config = { 
		RaiseError => 1,
		AutoCommit => 1,
	};

	my $dsn = "dbi:Pg:database=$db_name;host=$host";
	my $dbh = DBIx::Simple->connect( $dsn, $user, $pass, $config );

	return $dbh;
}

=head2

	my $sql = q~select * from table where id = ?~;
	my $rs  = $db->fetch( sql => $sql );
	my $rs  = $db->fetch( sql => $sql, values => 1234, single => 1 );
	my $rs  = $db->fetch( sql => $sql, values => [ 1, 'two' ] );


=cut;

sub fetch {
	my ( $self, %args ) = @_;

	my $sql     = $args{sql};
	my $map     = $args{map};
	my $single  = $args{single};
	my $values  = $args{values};
	my @values  = ref $values eq 'ARRAY' ? @{ $values } : ( $values ) if defined $values;
	my $lc_cols = $args{lc_cols} || 0;

	my $result = {};

	if ( $sql && $sql =~ /(select|desc)/i ) {

		my ( $success, $error );

		my $dbh          = $self->connect();
		$dbh->lc_columns = $lc_cols;

		eval { 
			if ( $map ) { 
				$success = $dbh->query( $sql, @values )->map_hashes( $map );
			} else { 
				$success = $dbh->query( $sql, @values )->hashes;
			}
		};

		if ( $@ ) { 

			$result->{error} = $@;

		} else {  

			if ( $single && ref $success eq 'ARRAY' ) {
				$success = @$success[0] ? @$success[0] : {};
			}
	
			$result->{success} = $success;
		}

		$dbh->disconnect();
	}

	return $result;
}

=head2

	my $sql = q~update table set key = ? where id = ?~;
	$db->write( sql => $sql, values => [ 'one', 2 ] );

=cut

sub write { 
	my ( $self, %args ) = @_;

	my $sql          = $args{sql};
	my $values       = $args{values};
	my @values       = ref $values eq 'ARRAY' ? @{ $values } : ( $values ) if defined $values;
	my $pg_insert_id = $args{pg_insert_id};

	my $result = {};

	if ( $sql ) { 
		my $dbh   = $self->connect();
		my $write = $dbh->query( $sql, @values );
		my $error = $dbh->{error};

		if ( $error ) { 
			$result->{error} = $error;
		} else {

			if ( $pg_insert_id ) { 

				my $res = $dbh->query( qq~select currval('$pg_insert_id') id~ )->map_hashes( 'id' );
				my @key = ref $res eq 'HASH' ? keys %$res : ();

				$result->{insert_id} = $key[0];

			} else { 
				if ( ref $dbh eq 'HASH' && $dbh->{dbh}{insert_id} ) { 
					$result->{insert_id} = $dbh->{dbh}{insert_id};
				}
			}

			$result->{success} = $write->{lc_columns};
		}

		$dbh->disconnect();
	}

	return $result;
}

1;
