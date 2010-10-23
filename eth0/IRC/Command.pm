#!/usr/bin/perl
# Copyright 2010, Olof Johansson <olof@ethup.se>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

=head1 eth0::IRC::Command

This module is the primary way to create new rules and commands. When a 
private message is received the B<private()> subroutine is called, and when 
a public message is received the B<public()> subroutine is called. Other 
events will probably be added eventually, but these two are usually the 
most important when writing a bot. How you organize this module is totally 
up to you, but the example module could be used as a basis for your rules 
and modifications. 

B<private()> and B<public()> are almost identicial, the arguments they are
given only differ on one point: B<public()> also gets the channel in which
the message was given. The arguments are as follows:

=over

=item * $irc

The POE::Component::IRC object, used to interact with the IRC session. See
the manual for POE::Component::IRC for information on how it's used.

=item * $auth

The eth0::Auth object, used to validate authentication details and get user
information.

=item * $be

The eth0::Backend object

=item * $who

Usermask of the sender of the command/message

=item * $chan 

The channel in which the message was sent; this is only present in public()
messages.

=item * $msg

The actual message/command

=back

=cut

use warnings;
no warnings qw/redefine/;
use strict;
package eth0::IRC::Command;

my $conf = main::conf();

sub public {
	my($irc, $auth, $be, $who, $chan, $msg) = @_;

	print "$conf->{bot}->{nick}\n";
	my($cmd) = $msg =~ /^(?:! | $conf->{bot}->{nick} [,:]\s*) (\S+)/x;
	my($nick) = split /!/, $who;
	print "$cmd\n";

	my %cmds = (
		echo => sub { cmd_echo($irc, $nick, $chan, $msg) },
	);

	return $cmds{$cmd}->() if(exists $cmds{$cmd});
}

sub private {
	my($irc, $auth, $be, $who, $msg) = @_;

	my($cmd) = $msg =~ /^(\S+)/;
	my($nick) = split /!/, $who;

	my %cmds = (
		echo => sub { cmd_echo($irc, $nick, $msg) },
		identify => sub {cmd_identify($irc, $auth, $who, $msg)},
		reload  => sub { cmd_reload($irc, $nick) },
	);

	return $cmds{$cmd}->() if(exists $cmds{$cmd});
	return $cmds{default}->($irc, $nick, $cmd);
}

sub cmd_default {
	my ($irc, $nick, $cmd) = @_;

	$irc->yield(privmsg => $nick => 
		"Unknown command: $cmd" 
	);
}

sub cmd_echo {
	my $msg = pop @_;
	($msg) = $msg =~ /echo\s+(.*)$/;

	if(@_ == 3) {
		my ($irc, $who, $chan) = @_;
		$irc->yield(privmsg => $chan => "$who: $msg" );
	} else {
		my ($irc, $who) = @_;
		$irc->yield(privmsg => $who => "$who: $msg" );
	}
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
