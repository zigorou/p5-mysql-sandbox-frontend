package MySQL::Sandbox::Frontend::Replication;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(MySQL::Sandbox::Frontend::Base);

__PACKAGE__->cmd_start('start_all');
__PACKAGE__->cmd_stop('stop_all');
__PACKAGE__->cmd_restart('restart_all');

__PACKAGE__->mk_accessors(qw/replication_directory nodes/);

use IPC::Cmd qw(can_run run);
use List::Util qw(first shuffle);
use MySQL::Sandbox::Frontend;
use MySQL::Sandbox::Frontend::Node;

our $DEFAULT_SLAVES = 2;

sub new {
    my ($class, $args) = @_;

    $args ||= +{};
    $args->{nodes} ||= [];

    $class->SUPER::new($args);
}

sub create {
    my ( $self, $version, $opts ) = @_;

    $opts ||= +{};
    $opts = +{
	how_many_slaves => $DEFAULT_SLAVES,
	%$opts,
    };

    $opts->{replication_directory} = delete $opts->{name} if (exists $opts->{name} && $opts->{name});

    if ($opts->{replication_directory}) {
	$self->replication_directory($opts->{replication_directory});
    }

    croak(q|Cannot run make_replication_sandbox|)
	unless ( can_run('make_replication_sandbox') );

    my @cmd = ( 'make_replication_sandbox', $version );

    push( @cmd, '--sandbox_directory', $self->sandbox_directory )
      if ( $self->sandbox_directory );
    push( @cmd, '--replication_directory', $self->replication_directory )
      if ( $self->replication_directory );
    push( @cmd, '--how_many_slaves', $opts->{how_many_slaves} );
    
    push( @cmd, '--verbose' );

    my ( $success, $err_code, $full_buf, $stdout, $stderr ) = run(
        command => \@cmd,
        verbose => $MySQL::Sandbox::Frontend::DEBUG,
        timeout => $MySQL::Sandbox::Frontend::TIMEOUT,
    );

    return $self->parse($opts, $stdout);
}

sub parse {
    my ($self, $opts, $stdout) = @_;

    my $node_size = $opts->{how_many_slaves};

    my $is_installed =
	$stdout->[-1] =~ m|replication directory installed in (.*)\n$|;

    my @nodes;

    for my $config_text ( map { $stdout->[$_] } 1 .. $node_size + 1 ) {
	my %config = $config_text =~ m|^([\w_]+)\s*=\s*([^=\s]*)\n|mg;

	my @fields =
          qw(db_user db_password upper_directory sandbox_directory sandbox_port);

	my $args = +{
	    map { ($_, $config{$_}) }
	    qw(db_user db_password upper_directory sandbox_directory sandbox_port),
	};

	$args->{is_master} = $config{sandbox_directory} eq 'master' ? 1 : 0;
	$args->{is_slave}  = !$args->{is_master};

	my $node = MySQL::Sandbox::Frontend::Node->new($args);

	push(@nodes, $node);
    }

    $self->nodes(\@nodes);
    
    return $is_installed;
}

sub master {
    my $self = shift;
    return $self->nodes->[0];
}

sub slave {
    my $self = shift;
    my $slave_cnt = scalar(@{$self->nodes}) - 1;
    return unless ($slave_cnt > 0);
    $self->nodes->[ (first { $_ } shuffle ( 1 .. $slave_cnt )) ];
}

sub base_directory {
    my $self = shift;
    $self->replication_abs_directory;
}

sub replication_abs_directory {
    my $self = shift;

    if ( -d $self->upper_directory && $self->replication_directory ) {
        return File::Spec->catdir( $self->upper_directory,
            $self->replication_directory );
    }
    else {
        return "";
    }
}

1;
