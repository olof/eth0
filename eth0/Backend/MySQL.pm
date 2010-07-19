#!/usr/bin/perl
use strict;
use warnings;
package eth0::Backend::MySQL;
use DBI;

sub new {
	my $class = shift;
	my $self = {
		@_
	};

	my $conf = main::conf();
	$self->{dbh} = DBI->connect(
		'DBI:mysql:'.
		'database='.$conf->{backend}->{database}.';'.
		'host='.$conf->{backend}->{host}.';',
		$conf->{backend}->{username},
		$conf->{backend}->{password}
	);

	bless($self, $class);
}

sub verify_userpass {
	my $self = shift;
	my ($nick, $pass) = @_;
	my $ret = get_ircmode($nick, $pass);

	return $ret if $ret eq 'authfail';
	return $ret if $ret eq 'miscfail';
	return 1;
}

sub get_ircmode {
	my $self = shift;
	my ($nick, $pass) = @_;

	my $sth = $self->{dbh}->prepare(<<'EOF');
		SELECT mode FROM users
		WHERE nick=? AND pass=?;
EOF

	$sth->execute($nick, $pass);

	if($sth->rows == 0) {
		return 'authfail';
	} elsif($sth->rows>1) {
		return 'miscfail';
	}

	return $sth->fetchrow_arrayref->[0];
}

1;
