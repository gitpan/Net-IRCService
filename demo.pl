#!/usr/bin/perl
use Net::IRCService;


# This is a untested example, just to show the basic's
# requires the fortune binary in the PATH
#
# Public domain, do what ever you whant with this, just dont blame me
# Kay Bærulfsen kaysb@uten.net
#

my $sendt=0;
my $ping_pong=0;
my $channel="#test";
my $servername="fortune.criten.net";
my $uplinkserver="heaven.no.eu.criten.net";


&add_timer(25, \&perform_ping);
&add_event_handler(EVENT_PING, \&send_users);
&add_event_handler(EVENT_RAW_IN, \&raw_in);


&init_service(
	SERVER_NAME => $servername,
	LOCALADDR => '192.168.0.50',
	LOCALPORT => 1800,
	PASSWORD => 'hyb7link',
	CAPAB	=> 'TS5 NICKIP',
	PROTOCOL => 'hybrid7'
		);

&main_loop;



sub raw_in {
	my $data=shift;
	if ($data=~ /:[^.]+ PRIVMSG $channel :fortune$/i) {
		my $fortune = `fortune -s`;
		$fortune =~ s/\n/ /g;
		$fortune =~ s/  / /g;
		$fortune =~ s/\t/ /g;
		&irc_send(":Fortune PRIVMSG $channel :$fortune");
	}		
}

sub send_users {
	return if $sendt;

	$sendt=1; # only send NICK and SJOIN once...
	my $ts=time;
	&irc_send("NICK Fortune 2 $ts +i fortune $servername $servername  :-");
	&irc_send(":$servername SJOIN $ts $channel +  :Fortune");
}

sub perform_ping {
	if ($ping_pong == 0) {
		$ping_pong=time;
		&irc_send(":$servername PING :$uplinkserver");
		&add_timer(25,\&perform_ping);
	} elsif ( (time - $ping_pong) > 60) {
		&close_connection("Ping timeout");
	}
}



