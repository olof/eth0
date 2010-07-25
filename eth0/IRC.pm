#!/usr/bin/perl
# Copyright 2010, Olof Johansson <olof@ethup.se>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

use warnings;
use strict;
package eth0::IRC;

use Config::YAML;
use POE qw/Component::IRC Component::IRC::Plugin::CTCP/;
use eth0::Backend;
use eth0::Auth;

my $be;
my $auth;
my $irc;
my $conf = main::conf();

sub execute {
	my $self = shift;
	($be, $auth) = @_;

	$irc = POE::Component::IRC->spawn(
		Nick => $conf->{bot}->{nick},
		Username => $conf->{bot}->{user},
		Ircname => $conf->{bot}->{realname},
		Server => $conf->{server}->{host},
		Port => $conf->{server}->{port},
		UseSSL => $conf->{server}->{ssl},
		useipv6 => $conf->{server}->{ipv6},
	) or die("POE::Component::IRC->spawn() failed ($@)");

	POE::Session->create(
		package_states => [
			'eth0::IRC' => [qw{
				_start 
				irc_001 
				irc_372
				irc_public 
				irc_msg
				irc_snotice
				irc_disconnected
			}],
		],
		heap => { irc => $irc },
	);

	$poe_kernel->run();
}

sub _start {
	my $heap = $_[HEAP];
	my $irc = $heap->{irc};

	$irc->plugin_add(
		'CTCP' => POE::Component::IRC::Plugin::CTCP->new(
			version => 'eth0-0.1',
			userinfo => 'eth0',
		)
	);

	$irc->yield( register => 'all' );
	$irc->yield( connect => {} );
	cmd_reload();

	return;
}

sub irc_001 {
	my $sender = $_[SENDER];

	my $irc = $sender->get_heap();
	print "Connected to ", $irc->server_name(), "\n";
	$irc->yield( join => $_->{chan} ) foreach @{$conf->{channels}};
	return;
}

sub irc_public {
	my ($sender, $who, $where, $msg) = @_[SENDER, ARG0 .. ARG2];

	if($msg =~ /^!reload\s*/) {
		cmd_reload($who, $where);
		return;
	}

	eth0::IRC::Command::public(
		$irc, $auth, $be, $who, $where, $msg
	) if $msg =~ /^!.+/;
}

sub irc_msg {
	my ($sender, $who, $me, $msg) = @_[SENDER, ARG0 .. ARG2];

	if($msg =~ /^reload\s*/) {
		my ($nick) = split /!/, $who;
		cmd_reload($who, $nick);
		return;
	}

	eth0::IRC::Command::private($irc, $auth, $be, $who, $msg);
}

sub irc_snotice {
	my ($sender, $what) = @_[SENDER, ARG0];
	print "snotice: $what\n";
}

sub irc_372 {
	my ($sender, $serv, $what) = @_[SENDER, ARG0, ARG1];	
	print "$what\n";
}

sub irc_disconnected {
	sleep 300;
	$irc->yield(connect=>{});
}

sub _default {
	my ($event, $args) = @_[ARG0 .. $#_];

	my @output = ( "$event: " );

	for my $arg ( @$args ) {
		if ( ref $arg eq 'ARRAY' ) {
			push @output, '[' . join(',', $arg) . ']';
		} else {
			push @output, "'$arg'";
		}
	}

	print join ' ', @output, "\n";
	return 0;
}

sub cmd_reload {
	my ($who, $to) = @_;

	delete $INC{'eth0/IRC/Command.pm'};
	my $msg = 'Reload successful.';

	unless( eval { require eth0::IRC::Command } ) {
		warn $@;
		$msg = 'Reload failed. See stdout.';
	}

	$irc->yield(privmsg => $to => $msg) if defined $who;
}

'hej då, små vänner';
