#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib ("${FindBin::Bin}/../lib");

use Data::Dumper;

use MySQL::Sandbox::Frontend;
use MySQL::Sandbox::Frontend::Single;
use SQL::Translator;

our $schema_yaml = $FindBin::Bin . '/../data/world.yaml';

$MySQL::Sandbox::Frontend::DEBUG = 1;

my $tr = SQL::Translator->new(
    parser   => 'YAML',
    producer => 'MySQL',
    validate => 1,
    no_comments => 1,
);

my $schema = $tr->translate( filename => $schema_yaml );
$schema =~ s|\n||g;

my $sb = MySQL::Sandbox::Frontend::Single->new;
$sb->create('5.1.36', +{ sandbox_directory => 'test' });

my $dbh = $sb->dbh;
$dbh->trace(1);
$dbh->do('create database world');
$dbh->do('use world');
for (split(';', $schema)) {
    $dbh->do($_);
}
my $sth = $dbh->prepare('show tables');
$sth->execute;
print Dumper($sth->fetchall_arrayref(+{}));
$sb->delete;
