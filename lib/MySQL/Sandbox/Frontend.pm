package MySQL::Sandbox::Frontend;

use strict;
use warnings;

our $VERSION = '0.01';

our $DEBUG   = 0;
our $TIMEOUT = 50;

use Carp;
use List::Util qw(first);

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

    $version ||= $class->latest_version;

    croak('please specify version') unless ($version);
    
    my $creator  = __PACKAGE__ . '::' . $TYPE_TO_MODULES{$type};
    my $frontend = $creator->new($opts->{new_args});

    $DEBUG = $opts->{debug};

    $frontend->create($version, $opts);
    $frontend;
}

sub find_versions {
    my $class = shift;

    my $binary_base = $ENV{SANDBOX_BINARY} || $ENV{HOME} . '/opt/mysql';
    $binary_base = '/opt/mysql' unless (-d $binary_base);

    my @entries = map { s|$binary_base/||; $_; } grep { -d && m|/\d+\.\d+\.\d+$| } glob($binary_base . '/*');
    wantarray ? @entries : \@entries;
}

sub latest_version {
    my $class = shift;

    my @entries = $class->find_versions;

    my $version = 
        first { $_ }
        sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] || $a->[2] cmp $b->[2] }
        map { [ split /\./ => $_ ] }
        @entries;

    return join('.', @$version);
}

1;
__END__

=head1 NAME

MySQL::Sandbox::Frontend - Control MySQL::Sandbox from perl code 

=head1 SYNOPSIS

  use MySQL::Sandbox::Frontend;

  local $, = "\n";

  my $sb = MySQL::Sandbox::Frontend->create('single', 'test', '5.1.36');
  $sb->start;

  my $dbh = $sb->dbh;
  my $rs = $dbh->selectall_arrayref('SHOW DATABASES;');
  print @$rs;
  
  $sb->delete;

=head1 DESCRIPTION

MySQL::Sandbox::Frontend is

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
