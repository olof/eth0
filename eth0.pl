#!/usr/bin/perl
use strict;
use warnings;

use eth0::Backend;
use eth0::IRC;
use eth0::Auth;
use Config::YAML;

my $conf = Config::YAML->new(
	config=>'/etc/eth0/config.yaml',
	server => { port=>6667, ssl=>0, ipv6=>1 },
);

sub conf { $conf } # get the conf object by accessing main::conf();

my $be = eth0::Backend->new(conf=>$conf);
my $auth = eth0::Auth->new(backend=>$be, conf=>$conf);
eth0::IRC->execute($be, $auth);

