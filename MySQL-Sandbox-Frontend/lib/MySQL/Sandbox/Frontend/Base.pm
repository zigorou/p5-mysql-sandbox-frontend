package MySQL::Sandbox::Frontend::Base;

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
      is_master
      is_slave
      /
);

use Carp;
use File::Spec;
use MySQL::Sandbox qw(
  is_a_sandbox
  get_sandbox_params
  is_sandbox_running
);
use IPC::Cmd qw(can_run run);

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
        croak( sprintf( "%d : %s", $err_code, join( '', @$stderr ) ) );
    }

    return $success;
}

sub start {
    my $self = shift;
    return if ($self->is_running);
    my @cmd = ( $self->sandbox_cmd('start') );
    my ( $success, $err_code, $full_buf, $stdout, $stderr ) = run(
        command => \@cmd,
	verbose => $MySQL::Sandbox::Frontend::DEBUG,
    );
    unless ($success) {
	croak( sprintf( "%d : %s", $err_code, join( '', @$stderr ) ) );
    }
}

sub restart {
    my $self = shift;
    my @cmd = ( $self->sandbox_cmd('restart') );
    my ( $success, $err_code, $full_buf, $stdout, $stderr ) = run(
        command => \@cmd,
	verbose => $MySQL::Sandbox::Frontend::DEBUG,
    );
    unless ($success) {
	croak( sprintf( "%d : %s", $err_code, join( '', @$stderr ) ) );
    }
    return 1;
}

sub stop {
    my $self = shift;
    return unless ($self->is_running);
    my @cmd = ( $self->sandbox_cmd('stop') );
    my ( $success, $err_code, $full_buf, $stdout, $stderr ) = run(
        command => \@cmd,
	verbose => $MySQL::Sandbox::Frontend::DEBUG,
    );
    unless ($success) {
	croak( sprintf( "%d : %s", $err_code, join( '', @$stderr ) ) );
    }
    return 1;
}

sub is_exists {
    my $self    = shift;
    my $abs_dir = $self->sandbox_abs_directory;
    is_a_sandbox($abs_dir) ? 1 : 0;
}

sub is_running {
    my $self = shift;
    my ($ret, $info);
    eval { ($ret, $info) = is_sandbox_running( $self->sandbox_abs_directory ); };
    $ret ? 1 : 0;
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

sub sandbox_cmd {
    my ($self, $cmd) = @_;
    File::Spec->catfile( $self->sandbox_abs_directory, $cmd );
}


1;
