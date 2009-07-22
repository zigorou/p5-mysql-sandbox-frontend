package MySQL::Sandbox::Frontend::Single;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
    qw/
      upper_directory
      sandbox_directory
      sandbox_port
      db_user
      db_password
      /
);

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
use Sys::HostIP;

use MySQL::Sandbox::Frontend;

sub new {
    my ( $class, $args ) = @_;

    $args ||= +{};
    $args = +{
        upper_directory => File::Spec->catdir( $ENV{HOME}, 'sandboxes' ),
        db_user         => 'msandbox',
        db_password     => 'msandbox',
        %$args,
    };

    $class->SUPER::new($args);
}

sub create {
    my ( $self, $version, $opts ) = @_;

    $opts ||= +{};
    $opts = +{
        force      => 0,
        check_port => 1,
        %$opts,
        no_confirm => 1,
    };

    if ($opts->{sandbox_directory}) {
	$self->sandbox_directory($opts->{sandbox_directory});
    }

    croak(q|Cannot run make_sandbox command|)
      unless ( can_run('make_sandbox') );

    my @cmd = ( 'make_sandbox', $version );

    for my $raw_opt ( grep { $opts->{$_} } qw/force check_port no_confirm/ ) {
        push( @cmd, '--' . $raw_opt );
    }

    push( @cmd, '--sandbox_directory', $self->sandbox_directory ) if ($self->sandbox_directory);

    my ( $success, $err_code, $full_buf, $stdout, $stderr ) = run(
        command => \@cmd,
        verbose => $MySQL::Sandbox::Frontend::DEBUG,
        timeout => $MySQL::Sandbox::Frontend::TIMEOUT,
    );

    unless ($success) {
	croak(sprintf("%d : %s", $err_code, join('', @$stderr)));
    }

    return $self->parse($stdout);
}

sub delete {
    my $self = shift;
    croak(q|Cannot run sbtool command|) unless ( can_run('sbtool') );
    my @cmd = ( 'sbtool', '-o', 'delete', '-s', $self->sandbox_abs_directory );

    my ( $success, $err_code, $full_buf, $stdout, $stderr ) = run(
        command => \@cmd,
        verbose => $MySQL::Sandbox::Frontend::DEBUG,
        timeout => $MySQL::Sandbox::Frontend::TIMEOUT,
    );

    unless ($success) {
        croak(sprintf("%d : %s", $err_code, join('', @$stderr)));
    }

    return $success;
}

sub parse {
    my ( $self, $stdout ) = @_;
    my $is_installed =
      $stdout->[-1] =~ m|^Your sandbox server was installed in (.*)\n$|;

    if ($is_installed) {
        my $config_text = $stdout->[1];
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
    my ($self, $database) = @_;

    my %dsn = (
	host => Sys::HostIP->ip,
	($database) ? (db => $database) : (),
	port => $self->sandbox_port,
    );

    return +{
	dsn => 'dbi:mysql:' . join( ';' => map { $_ . '=' . $dsn{$_} } keys %dsn ),
	user => $self->db_user,
	password => $self->db_password,
    };
}

sub dbh {
    my ($self, $database, $args) = @_;
    $args ||= +{};
    my $dbh_args = $self->dbh_args($database);
    my $dbh = DBI->connect(@$dbh_args{qw/dsn user password/}, $args);
    return $dbh;
}

sub sandbox_abs_directory {
    my $self = shift;

    if ( -d $self->upper_directory && $self->sandbox_directory ) {
        return File::Spec->catdir( $self->upper_directory, $self->sandbox_directory );
    }
    else {
        return "";
    }
}

sub is_exists {
    my $self    = shift;
    my $abs_dir = $self->sandbox_abs_directory;
    is_a_sandbox($abs_dir) ? 1 : 0;
}

sub is_running {
    my $self = shift;
    my $ret;
    eval {
	$ret = is_sandbox_running($self->sandbox_abs_directory);
    };
    $ret ? 1 : 0;
}

1;
