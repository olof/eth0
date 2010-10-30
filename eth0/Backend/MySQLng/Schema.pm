#!/usr/bin/perl
use strict;
use warnings;
package eth0::Backend::MySQLng::Schema;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_namespaces();

1;

