#!/usr/bin/perl
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

sub mode {
	my $self = shift;
	my($nick, $pass) = @_;
	return $self->{be}->get_ircmode($nick, $pass);
}

sub verify {
	my $self = shift;
	my ($nick, $pass) = @_;
	my $ret = $self->mode($nick, $pass);

	return $ret if $ret eq 'authfail';
	return $ret if $ret eq 'miscfail';
	return 1;
}

1;
