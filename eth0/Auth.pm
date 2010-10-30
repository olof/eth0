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
		status=>{}
	};

	if(not defined $self->{backend}) {
		croak('You fail, Auth didnt get the backend');
	}

	bless $self, $class;
}

sub authen {
	my $self = shift;
	my ($nick, $realnick, $pass) = @_;
	#my $hash = sha256_hex(sha256_hex($nick.$pass));
	#$hash = $pass;
	
	my $e = $self->{backend}->verify($realnick, $pass);
	return 'authfail' if $e != 1;
	$self->{status}->{$nick} = $self->level($realnick);
	return 'ok';
}

sub status {
	my $self = shift;
	my ($nick) = @_;

	$self->{status}->{$nick};
}

sub del_status {
	my $self = shift;
	my ($nick) = @_;

	delete $self->{status}->{$nick};
}

sub ircmode {
	my $self = shift;
	my ($nick) = @_;

	my $level = $self->level($nick);
	return undef unless defined $level;

	my %modes = (
		1 => 'v',
		2 => 'o',
		3 => 'o',
	);

	return undef unless exists $modes{$level};
	return $modes{$level};
}

sub level {
	my $self = shift;
	my ($nick) = @_;

	$self->{backend}->level($nick);
}

1;
