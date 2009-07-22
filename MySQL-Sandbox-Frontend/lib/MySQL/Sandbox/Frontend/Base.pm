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
}

sub start {
}

sub stop {
}

sub restart {
}

sub dbh {
}

sub dbh_args {
}

sub dir {
}

sub is_sandbox {
}

sub is_running {
}


1;
