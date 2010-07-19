#!/usr/bin/perl
use warnings;
use strict;
package eth0::IRC::Command;

my $conf = main::conf();

sub public {
	my($irc, $auth, $be, $who, $chan, $msg) = @_;

	my($cmd) = $msg =~ /^!(\S+)/;
	my($nick) = split /!/, $who;

	my %cmds = (
		echo => sub { cmd_echo($irc, $nick, $chan, $msg) },
		88 => sub { cmd_88($irc, $chan) },
		reload  => sub { cmd_reload($irc, $chan) },
	);

	return $cmds{$cmd}->() if(exists $cmds{$cmd});
}

sub private {
	my($irc, $auth, $be, $who, $msg) = @_;

	my($cmd) = $msg =~ /^(\S+)/;
	my($nick) = split /!/, $who;

	my %cmds = (
		default => sub { cmd_default($irc, $who, $cmd) },
		echo => sub { cmd_echo($irc, $nick, $msg) },
		identify => sub {cmd_identify($irc, $auth, $who, $msg)},
		reload  => sub { cmd_reload($irc, $nick) },
	);

	return $cmds{$cmd}->() if(exists $cmds{$cmd});
	return $cmds{default}->();
}

sub cmd_default {
	my ($irc, $nick, $cmd) = @_;

	$irc->yield(privmsg => $nick => 
		"Unknown command: $cmd" 
	);
}

sub cmd_echo {
	my $msg = pop @_;
	$msg=~s/^!?echo *//;

	if(@_ == 3) {
		my ($irc, $who, $chan) = @_;
		$irc->yield(privmsg => $chan => "$who: $msg" );
	} else {
		my ($irc, $who) = @_;
		$irc->yield(privmsg => $who => "$who: $msg" );
	}
}

sub cmd_88 {
	my ($irc, $chan) = @_;
	$irc->yield(privmsg => $chan => "All makt åt Tengil, vår befriare" );
}

sub cmd_identify {
	my ($irc, $auth, $who, $cmd) = @_;

	my($snick) = split /!/, $who;
	my $nick;
	my $pass;
	
	if($cmd=~/^identify +(\S+) +(\S+) *$/) {
		$nick = $1;
		$pass = $2;
	} elsif($cmd=~/^identify +(\S+) *$/) {
		($nick) = $snick;
		$pass = $1;
	} else {
		$irc->yield(privmsg => $snick => 
			"usage: identify [nickname] <password>" 
		);
		
		return;
	}

	my $mode = $auth->mode($nick, $pass);

	if(not defined $mode) {
		$irc->yield(privmsg => $snick => 
			"error: undef" 
		);
	} elsif($mode eq 'miscfail') {
		$irc->yield(privmsg => $snick => 
			"error: misc" 
		);
	} elsif($mode eq 'authfail') {
		$irc->yield(privmsg => $snick => 
			"error: incorrect username/password" 
		);
	} else {
		$irc->yield(privmsg => $snick => 
			"success: welcome, $snick (+$mode)" 
		);

		foreach(@{$conf->{channels}}) {
			$irc->yield(mode => $_->{chan} => "+$mode $snick");
		}
	}
}

1;
