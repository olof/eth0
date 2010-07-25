#!/usr/bin/perl
# Copyright 2010, Olof Johansson <olof@ethup.se>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

use strict;
use warnings;
package eth0::Auth;

use eth0::Backend;
use Digest::SHA qw/sha256_hex/;

sub new {
	my $class = shift;
	my $self = {
		@_,
	};

	if(not defined $self->{backend}) {
		croak('You fail, Auth didnt get the backend');
	}

	bless $self, $class;
}

sub mode {
	my $self = shift;
	my ($nick, $pass) = @_;
	my $hash = sha256_hex(sha256_hex($nick.$pass));

	if((my $authstatus = $self->{backend}->verify($nick, $hash)) ne 1) {
		return $authstatus;
	}

	my $mode = $self->{backend}->mode($nick, $hash);

	if($mode eq 'o' or $mode eq 'v') {
		return $mode;
	}

	return undef;
}

1;
