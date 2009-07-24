package MySQL::Sandbox::Frontend::Replication;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(MySQL::Sandbox::Frontend::Base);

__PACKAGE__->mk_accessors(qw/replication_directory/);

use IPC::Cmd qw(can_run run);
use MySQL::Sandbox::Frontend;

use Data::Dumper;

sub create {
    my ( $self, $version, $opts ) = @_;

    $opts ||= +{};
    $opts = +{
	how_many_slaves => 2,
	%$opts,
    };

    if ($opts->{replication_directory}) {
	$self->replication_directory($opts->{replication_directory});
    }
    
    if ( $opts->{sandbox_directory} ) {
	$self->sandbox_directory( $opts->{sandbox_directory} );
    }

    croak(q|Cannot run make_replication_sandbox|)
	unless ( can_run('make_replication_sandbox') );

    my @cmd = ( 'make_replication_sandbox', $version );

    push( @cmd, '--sandbox_directory', $self->sandbox_directory )
      if ( $self->sandbox_directory );
    push( @cmd, '--replication_directory', $self->replication_directory )
      if ( $self->replication_directory );
    
    push( @cmd, '--verbose' ) if ($MySQL::Sandbox::Frontend::DEBUG);

    my ( $success, $err_code, $full_buf, $stdout, $stderr ) = run(
        command => \@cmd,
        verbose => $MySQL::Sandbox::Frontend::DEBUG,
        timeout => $MySQL::Sandbox::Frontend::TIMEOUT,
    );

    print Dumper($stdout);
}

1;
