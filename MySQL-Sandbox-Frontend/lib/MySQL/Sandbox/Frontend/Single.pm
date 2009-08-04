package MySQL::Sandbox::Frontend::Single;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(MySQL::Sandbox::Frontend::Base);

__PACKAGE__->cmd_start('start');
__PACKAGE__->cmd_stop('stop');
__PACKAGE__->cmd_restart('restart');

use Carp;
use Data::Dumper;
use DBI;
use File::Spec;
use MySQL::Sandbox qw(
  is_a_sandbox
  get_sandbox_params
  is_sandbox_running
);
use IPC::Cmd qw(can_run run);
use List::Util qw(first);
use Sys::HostIP;
use MySQL::Sandbox::Frontend;

sub create {
    my ( $self, $version, $opts ) = @_;

    $opts ||= +{};
    $opts = +{
        force      => 0,
        check_port => 1,
        %$opts,
        no_confirm => 1,
    };

    if ( $opts->{sandbox_directory} ) {
        $self->sandbox_directory( $opts->{sandbox_directory} );
    }

    croak(q|Cannot run make_sandbox command|)
      unless ( can_run('make_sandbox') );

    my @cmd = ( 'make_sandbox', $version );

    for my $raw_opt ( grep { $opts->{$_} } qw/force check_port no_confirm/ ) {
        push( @cmd, '--' . $raw_opt );
    }

    push( @cmd, '--sandbox_directory', $self->sandbox_directory )
      if ( $self->sandbox_directory );
    push( @cmd, '--verbose' ) if ($MySQL::Sandbox::Frontend::DEBUG);

    my ( $success, $err_code, $full_buf, $stdout, $stderr ) = run(
        command => \@cmd,
        verbose => $MySQL::Sandbox::Frontend::DEBUG,
        timeout => $MySQL::Sandbox::Frontend::TIMEOUT,
    );

    unless ($success) {
        croak( sprintf( "%d : %s", $err_code, join( '', @$stderr ) ) );
    }

    return $self->parse($stdout);
}

sub parse {
    my ( $self, $stdout ) = @_;

    my $is_installed =
      $stdout->[-1] =~ m|^Your sandbox server was installed in (.*)\n$|;

    if ($is_installed) {
        my $config_text = first { m/installing with the following parameters/ } map { $stdout->[$_] } (1, 2);
        my %config = $config_text =~ m|^([\w_]+)\s*=\s*([^=\s]*)\n|mg;
        my @fields =
          qw(db_user db_password upper_directory sandbox_directory sandbox_port);

        for (@fields) {
            $self->$_( $config{$_} );
        }
    }

    return $is_installed;
}

sub dbh_args {
    my ( $self, $database ) = @_;

    my %dsn = (
        host => Sys::HostIP->ip,
        ($database) ? ( db => $database ) : (),
        port => $self->sandbox_port,
    );

    return +{
        dsn => 'dbi:mysql:'
          . join( ';' => map { $_ . '=' . $dsn{$_} } keys %dsn ),
        user     => $self->db_user,
        password => $self->db_password,
    };
}

sub dbh {
    my ( $self, $database, $args ) = @_;
    $args ||= +{};
    my $dbh_args = $self->dbh_args($database);
    my $dbh = DBI->connect( @$dbh_args{qw/dsn user password/}, $args );
    return $dbh;
}

sub base_directory {
    my $self = shift;
    $self->sandbox_abs_directory;
}

sub sandbox_abs_directory {
    my $self = shift;

    if ( -d $self->upper_directory && $self->sandbox_directory ) {
        return File::Spec->catdir( $self->upper_directory,
            $self->sandbox_directory );
    }
    else {
        return "";
    }
}

# sub load {
#     my ($self, $opts) = @_;

#     my $schemas	 = delete $opts->{schemas};
#     my $fixtures = delete $opts->{fixtures};

#     $self->load_schemas($schemas);
#     $self->load_fixtures($fixtures);
# }

# sub load_schemas {
#     my ($self, $schemas) = @_;

#     my $tr = SQL::Translator->new(
# 	parser	    => 'YAML',
# 	producer    => 'MySQL',
# 	validate    => 1,
# 	no_comments => 1,
#     );

#     for my $db (keys %$schemas) {
# 	my $schema = $tr->translate( filename => $schemas->{$db} );
# 	my $dbh = $self->dbh(undef, +{ AutoCommit => 0, RaiseError => 1 });
# 	$dbh->trace(1);

# 	eval {
# 	    $dbh->do(sprintf("create database %s", $db));
# 	    $dbh->do(sprintf("use %s", $db));
# 	    for (grep { $_ !~ /^\s*$/ } split ';' => $schema) {
# 	    	$dbh->do($_);
# 	    }
# 	    $dbh->commit;
# 	};
# 	if ($@ || $dbh->errstr) {
# 	    my $err = $@ || $dbh->errstr;
# 	    undef $@;
# 	    $dbh->rollback;
# 	    croak($err);
# 	}
#     }
# }

# sub load_fixtures {
#     my ($self, $fixtures) = @_;
# }

1;

__END__

