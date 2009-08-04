package MySQL::Sandbox::Frontend;

use strict;
use warnings;

our $VERSION = '0.01';

our $DEBUG   = 0;
our $TIMEOUT = 50;

use Carp;

use MySQL::Sandbox::Frontend::Node;
use MySQL::Sandbox::Frontend::Replication;

our %TYPE_TO_MODULES = (
    single	=> 'Node',
    replication => 'Replication',
);

#
# MySQL::Sandbox::Frontend->create('replication', 'rtest', '5.1.36', +{ how_many_slaves => 2 })
# 
sub create {
    my ($class, $type, $name, $version, $opts) = @_;
    
    croak("No support type: " . $type) unless (exists $TYPE_TO_MODULES{$type});
    
    $opts ||= +{};
    $opts = +{
	name => $name,
	new_args => +{},
	debug => 0,
	%$opts,
    };

    my $creator  = __PACKAGE__ . '::' . $TYPE_TO_MODULES{$type};
    my $frontend = $creator->new($opts->{new_args});

    $DEBUG = $opts->{debug};

    $frontend->create($version, $opts);
    $frontend;
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
