#!/usr/bin/perl
use strict;
use warnings;
package eth0::Backend::MySQLng::Schema::Result::User;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('user');
__PACKAGE__->add_columns('uid', 'nick', 'pass', 'email', 'level');
__PACKAGE__->set_primary_key('uid');

1;
