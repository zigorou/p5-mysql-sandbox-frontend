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

my $sb = MySQL::Sandbox::Frontend::Single->new;
$sb->create('5.1.36', +{ sandbox_directory => 'test' });

print STDERR Dumper($sb);

$sb->delete;
