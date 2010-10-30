#!/usr/bin/perl
use strict;
use warnings;
package eth0::Backend::MySQLng;
use eth0::Backend::MySQLng::Schema;

sub new {
	my $class = shift;
	my $self = {
		@_,
		conf => main::conf(),
	};

	$self->{orm} = eth0::Backend::MySQLng::Schema->connect(
		'DBI:mysql:'.
		'database='.$self->{conf}->{backend}->{database}.';'.
		'host='.$self->{conf}->{backend}->{host}.';',
		$self->{conf}->{backend}->{username},
		$self->{conf}->{backend}->{password}
	);

	bless($self, $class);
}

sub verify {
	my $self = shift;
	my ($nick, $pass) = @_;

	my $s = $self->{orm};
	my $rs = $s->resultset('User')->single({nick=>$nick, pass=>$pass});

	if(defined $rs) {
		return 1;
	} else {
		return 0;
	}
}

sub level {
	my $self = shift;
	my($nick) = @_;

	my $s = $self->{orm};
	my $rs = $s->resultset('User')->single({nick=>$nick});

	return undef unless $rs;

	return $rs->get_column('level');
}

1;
