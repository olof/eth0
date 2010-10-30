#!/usr/bin/perl
# Copyright 2010, Olof Johansson <olof@ethup.se>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

use strict;
use warnings;
package eth0::Backend;
use Carp;

sub new {
	my $class = shift;
	my $self = {
		@_,
	};

	my $conf = main::conf();
	my $be = 'eth0::Backend::'.$conf->{backend}->{backend};
	my $bef = $be.'.pm';
	$bef=~s/::/\//g;

	eval { require $bef } or croak("Invalid backend: $be ($@)");
	$self->{be} = $be->new();

	bless $self, $class;
}

sub level {
	my $self = shift;
	my($nick, $pass) = @_;
	$self->{be}->level($nick, $pass);
}

sub verify {
	my $self = shift;
	my ($nick, $pass) = @_;
	$self->{be}->verify($nick, $pass);
}

1;
