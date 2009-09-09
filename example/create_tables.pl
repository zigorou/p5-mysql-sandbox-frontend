#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib ($FindBin::Bin . '/../lib');

use Test::More;
use Data::Dumper;
use MySQL::Sandbox::Frontend;

my $sb = MySQL::Sandbox::Frontend->create('single', 'test', undef, +{ debug => 0, });
ok($sb, 'create sandbox');

my $dbh = $sb->dbh;
isa_ok($dbh, 'DBI::db');

$dbh->do('create database miniblog;');
$dbh->do('use miniblog;');
$dbh->do(<< 'SCHEMA');
CREATE TABLE user (
    id int(10) unsigned NOT NULL AUTO_INCREMENT,
    screen_name varchar(255) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=innodb;
SCHEMA

$dbh->do(<< 'SCHEMA');
CREATE TABLE message (
    id int(10) unsigned NOT NULL AUTO_INCREMENT,
    user_id int (10) unsigned NOT NULL,
    body varchar(255) NOT NULL,
    PRIMARY KEY (id),
    KEY userid_id_id(user_id, id)
) ENGINE=innodb;
SCHEMA

$dbh->do(<< 'SCHEMA');
CREATE TABLE follower (
    id int(10) unsigned NOT NULL AUTO_INCREMENT,
    user_id int (10) unsigned NOT NULL,
    follower_id int (10) unsigned NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (user_id, follower_id),
    KEY user_id_follower_id (user_id, follower_id),
    KEY follower_id(follower_id)
) ENGINE=innodb;
SCHEMA

is_deeply($dbh->selectall_arrayref('SHOW TABLES;'), [ ['follower'], ['message'], ['user'] ], 'created tables');

ok($sb->delete, 'delete sandbox');

done_testing;
