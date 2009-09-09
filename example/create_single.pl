#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib ($FindBin::Bin . '/../lib');

use Test::More;

use MySQL::Sandbox::Frontend;

my $sb = MySQL::Sandbox::Frontend->create('single', 'test', undef, +{ debug => 0, });
ok($sb, 'create sandbox');

my $dbh = $sb->dbh;
isa_ok($dbh, 'DBI::db');

my $rs = $dbh->selectall_arrayref('SHOW DATABASES;');

is_deeply($rs, [ ['information_schema'], ['mysql'], ['test'] ], 'databases');
  
ok($sb->delete, 'delete sandbox');

done_testing;
