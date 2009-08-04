package MySQL::Sandbox::Frontend::Base;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Class::Accessor::Fast Class::Data::Inheritable);

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

__PACKAGE__->mk_classdata($_) for (qw/cmd_start cmd_stop cmd_restart/);

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
	is_master       => 1,
	is_slave        => 0,
        %$args,
    };

    $class->SUPER::new($args);
}

sub create {
}

sub delete {
    my $self = shift;
    croak(q|Cannot run sbtool command|) unless ( can_run('sbtool') );
    my @cmd = ( 'sbtool', '-o', 'delete', '-s', $self->base_directory );

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
    my @cmd = ( $self->sandbox_cmd($self->cmd_start) );
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
    my @cmd = ( $self->sandbox_cmd($self->cmd_restart) );
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
    my @cmd = ( $self->sandbox_cmd($self->cmd_stop) );
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
    my $abs_dir = $self->base_directory;
    is_a_sandbox($abs_dir) ? 1 : 0;
}

sub is_running {
    my $self = shift;
    my ($ret, $info);
    eval { ($ret, $info) = is_sandbox_running( $self->base_directory ); };
    $ret ? 1 : 0;
}

sub base_directory {
    croak('abstract method');
}

sub sandbox_cmd {
    my ($self, $cmd) = @_;
    File::Spec->catfile( $self->base_directory, $cmd );
}


1;
