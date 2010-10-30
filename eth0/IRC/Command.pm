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
use POSIX qw/strftime/;

my $conf = main::conf();
my $loadtime = time;

my @threats = (
	"I'm gonna rape you in your mouth",
	"I'm gonna take you out and fuck you in the streets",
	"Your mother has a smooth forehead",
	"Yo poppa so stupid he studied for a drug test!",
	"Yo Mom so stupid that Oxford had to change the definition of Dumb... it now read: Dumb(n) - yo' Mama",
	"If yo Momma n Poppa got a divorce, heck, they'd still be Brother and Sister",
	'Are you still an ALCOHOLIC?',
	'Eat shit -- billions of flies can\'t be wrong.',
	'Go play in traffic',
	'Fuck you and anybody who looks like you.',
	'Nu passar du dig; du är ute på hal is och cyklar!',
);

my @random = (
	'I was making donuts and now I\'m on a bus!',
	'All this time I\'ve been VIEWING a RUSSIAN MIDGET SODOMIZE a HOUSECAT!',
	'Now KEN and BARBIE are PERMANENTLY ADDICTED to MIND-ALTERING DRUGS',
	'I joined scientology at a garage sale!!',
	'Did I say I was a sardine?  Or a bus???',
	'Could I have a drug overdose?',
	'Wow!  Look!!  A stray meatball!!  Let\'s interview it!',
	'Save the whales.  Club a seal instead.',
	'Nuke the unborn gay female whales for Jesus.',
	'The hell with the prime directive!  Let\'s kill something!',
	'Sometimes it happens.  People just explode.  Natural causes.',
	'Never hit a man with glasses; hit him with a baseball bat.',
	'Just don\'t create a file called -rf.  :-)',
	'cock shit fuck',
);

sub classify_msg {
	my $msg = shift;

	my @classes = ( 
		{
			class=>'cmd',
			f=> sub { 
				my $a = shift;
				$a =~ qr/^(?:
					! | 
					$conf->{bot}->{nick} [,:]\s* \S+
				)/x 
			},
		}, {
			class=>'88',
			f=> sub {
				my $a = shift;
				$a =~ qr/^\s*88\b/
			},
		}, {
			class=>'random',
			f=> sub {
				my $a = shift;
				length($a) % 10 == 0;
			},
		},
	);

	foreach my $c (@classes) {
		return $c->{class} if $c->{f}->($msg);
	}

	return undef;
}

sub public {
	my($irc, $auth, $be, $who, $chan, $msg) = @_;
	my($nick) = split /!/, $who;

	my %classes = (
		cmd => sub { 
			public_cmd($irc, $auth, $be, $who, $chan, $msg) 
		},
		88 => sub { 
			my $m = "$nick: ".$threats[int(rand(@threats))];
			ircsay($irc, $chan, $m);
			return;
		},
		random => sub {
			my $m = $random[int(rand(@random))];
			ircsay($irc, $chan, $m);
			return;
		},
	);

	my $class = classify_msg($msg);

	return $classes{$class}->() if exists $classes{$class};
}

sub private {
	my($irc, $auth, $be, $who, $msg) = @_;
	my($nick) = split /!/, $who;

	my %classes = (
		cmd => sub { 
			private_cmd($irc, $auth, $be, $who, $msg) 
		},
		88 => sub { 
			my $m = "$nick: ".$threats[int(rand(@threats))];
			ircsay($irc, $nick, $m);
			return;
		},
		random => sub {
			my $m = $random[int(rand(@random))];
			ircsay($irc, $nick, $m);
			return;
		},
	);

	my $class = classify_msg($msg);
	$class //= 'cmd';

	return $classes{$class}->() if exists $classes{$class};
}

sub public_cmd {
	my($irc, $auth, $be, $who, $chan, $msg) = @_;
	my($nick) = split /!/, $who;

	my($cmd) = $msg =~ qr/^(?:
		! | 
		$conf->{bot}->{nick} [,:]\s* (\S+)
	)/x;

	my %cmds = (
		echo => sub { cmd_echo($irc, $nick, $chan, $msg) },
	);

	return $cmds{$cmd}->() if(defined $cmd and exists $cmds{$cmd});
}

sub private_cmd {
	my($irc, $auth, $be, $who, $chan, $msg) = @_;
	my($nick) = split /!/, $who;

	my($cmd) = $msg =~ qr/^(?:
		! | 
		$conf->{bot}->{nick} [,:]\s* (\S+)
	)/x;

	my %cmds = (
		echo => sub { cmd_echo($irc, $nick, $msg) },
		identify => sub {cmd_identify($irc, $auth, $who, $msg)},
		status => sub { cmd_status($irc, $auth, $nick) },
		op => sub { cmd_op($irc, $auth, $nick) },
	);

	return $cmds{$cmd}->() if(defined $cmd and exists $cmds{$cmd});
	return cmd_default($irc, $nick, $cmd);
}

sub ircsay {
	my($irc, $chan, $msg) = @_;
	$irc->yield(privmsg=>$chan=>$msg);
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

sub cmd_status {
	my $self;
	my ($irc, $auth, $who) = @_;
	my $status = $auth->status($who);

	if(not defined $status) {
		ircsay($irc, $who, 'This requires authentication.'); 
		return;
	} elsif($status != 3) {
		ircsay($irc, $who, 'Current status: I\'m absing'); 
		return;
	}

	my $str = strftime '%Y-%m-%d %H:%M:%S %Z', localtime $loadtime;
	$irc->yield(privmsg=>$who=>"loaded: $str");
}

sub cmd_identify {
	my ($irc, $auth, $who, $cmd) = @_;

	my($snick) = split /!/, $who;
	my $nick;
	my $pass;
	
	if($cmd=~/^identify +(\S+) +(\S+) *$/) { $nick = $1; $pass = $2;
	} elsif($cmd=~/^identify +(\S+) *$/) {
		$nick = $snick;
		$pass = $1;
	} else {
		$irc->yield(privmsg => $snick => 
			"usage: identify [nickname] <password>" 
		);
		
		return;
	}

	my $a = $auth->authen($snick, $nick, $pass);
	if($a ne 'ok') {
		my %errmsgs = (
			authfail=>'incorrect username/password',
			miscfail=>'misc',
		);

		$a = 'miscfail' unless exists $errmsgs{$a};
		$irc->yield(privmsg=>$snick=>"error: undef $errmsgs{$a}");
		return;
	}
	
	my $mode = $auth->ircmode($nick);
	return unless defined $mode;

	$irc->yield(privmsg => $snick => "success: welcome, $snick (+$mode)");

	cmd_op($irc, $auth, $snick);
}

sub cmd_op {
	my ($irc, $auth, $nick) = @_;

	return unless $auth->status($nick);
	my $mode = $auth->ircmode($nick);
	return unless $mode;

	foreach(@{$conf->{channels}}) {
		$irc->yield(mode => $_->{chan} => "+$mode $nick");
	}
}

1;
