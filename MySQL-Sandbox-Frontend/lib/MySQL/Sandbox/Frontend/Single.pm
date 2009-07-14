package MySQL::Sandbox::Frontend::Single;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/
				upper_directory
				sandbox_directory
				sandbox_port
				db_user
				db_password
			    /);

use Carp;
use Data::Dumper;
use File::Spec qw(catdir);
use MySQL::Sandbox qw(
			 is_a_sandbox
			 get_sandbox_params
			 is_sandbox_running
		 );
use IPC::Cmd qw(can_run run);

use MySQL::Sandbox::Frontend;

sub new {
    my ($class, $args) = @_;

    $args ||= +{};
    $args = +{
	upper_directory => catdir($ENV{HOME}, 'sandboxes'),
	db_user		=> 'msandbox',
	db_password	=> 'msandbox',
	%$args,
    };
    
    $class->SUPER::new($args);
}

sub create {
    my ($self, $version, $opts) = @_;

    $opts ||= +{};
    $opts = +{
	force => 0,
	check_port => 1,
	%$opts,
	no_confirm => 1,
    };

    croak(q|Cannot run make_sandbox command|) unless(can_run('make_sandbox'));

    my @cmd = ('make_sandbox', $version);
    
    for my $raw_opt (grep { $opts->{$_} } qw/force check_port no_confirm/) {
	push(@cmd, '--' . $raw_opt);
    }

    my ($success, $err_code, $full_buf, $stdout, $stderr) = run(
	command => \@cmd,
	verbose => $MySQL::Sandbox::Frontend::DEBUG,
	timeout => $MySQL::Sandbox::Frontend::TIMEOUT,
    );

    unless ($success) {
	croak($err_code);
    }

    return $self->parse($stdout);
}

sub parse {
    my ($self, $stdout) = @_;
    my $is_installed = $stdout->[-1] =~ m|^Your sandbox server was installed in (.*)\n$|;

    if ($is_installed) {
	my $config_text  = $stdout->[2];
	my %config = $config_text =~ m|^([\w_]+)\s*=\s*([^=\s]*)\n|mg;
	my @fields = qw(db_user db_password upper_directory sandbox_directory sandbox_port);

	for (@fields) {
	    $self->$_($config{$_});
	}
    }

    return $is_installed;
}

sub sandbox_abs_directory {
    my $self = shift;

    if (-d $self->upper_directory && $self->sandbox_directory) {
	return cat_dir($self->upper_directory, $self->sandbox_directory);
    }
    else {
	return "";
    }
}

sub is_exists {
    my $self = shift;

    is_a_sandbox();
}

sub is_running {
    my $self = shift;
}

1;
