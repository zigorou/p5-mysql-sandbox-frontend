package MySQL::Sandbox::Frontend;

use strict;
use warnings;

our $VERSION = '0.01';

our $DEBUG   = 0;
our $TIMEOUT = 50;

use Carp;
use Data::Dumper;
use MySQL::Sandbox qw(
    is_a_sandbox
    get_sandbox_params
    is_sandbox_running
);
use IPC::Cmd qw(can_run run);

sub make_sandbox {
    my ($class, $version, $args) = @_;

    $args ||= +{};
    $args = +{
	force => 0,
	check_port => 1,
	%$args,
	no_confirm => 1,
    };

    croak(q|Cannot run make_sandbox command|) unless(can_run('make_sandbox'));

    my @cmd = ('make_sandbox', $version);
    
    for my $raw_opt (grep { $args->{$_} } qw/force check_port no_confirm/) {
	push(@cmd, '--' . $raw_opt);
    }

    my ($success, $err_code, $full_buf, $stdout, $stderr)
	= run( command => \@cmd, verbose => $DEBUG, timeout => 40 );

    unless ($success) {
	croak($err_code);
    }

    print Dumper($stdout);
}

sub make_replication_sandbox {
}

sub make_multiple_sandbox {
}

1;
__END__

=head1 NAME

MySQL::Sandbox::Frontend -

=head1 SYNOPSIS

  use MySQL::Sandbox::Frontend;

=head1 DESCRIPTION

MySQL::Sandbox::Frontend is

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
