package Net::IRCService;

#
# Net::IRCService
# Copyright (C) 2003  Kay Sindre Baerulfsen
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#


use 5.006;
#use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

	&ircsend

	&init_service
	&close_connection
	&add_event_handler

	&do_one_loop
	&main_loop

	&add_timer
	&del_timer

	&irc_send
	&irc_send_now

	&send_whois

	%remote_capab
	%our_capab

	EVENT_PRIVMSG
	EVENT_WHOIS
	EVENT_HSNICK
	EVENT_SNICK
	EVENT_CNICK
	EVENT_SERVER
	EVENT_STOPIC
	EVENT_COPIC
	EVENT_INVITE
	EVENT_VERSION
	EVENT_QUIT
	EVENT_SQUIT
	EVENT_KILL
	EVENT_ERROR
	EVENT_AWAY
	EVENT_PING
	EVENT_PONG
	EVENT_PASS
	EVENT_WALLOPS
	EVENT_OPERWALL
	EVENT_ADMIN
	EVENT_NOTICE
	EVENT_GNOTICE
	EVENT_PART
	EVENT_MOTD
	EVENT_MODE
	EVENT_KICK
	EVENT_SVINFO
	EVENT_CAPAB
	EVENT_SSJOIN
	EVENT_CSJOIN
	EVENT_AKILL
	EVENT_RAKILL
	EVENT_SVSKILL
	EVENT_KNOCKLL
	EVENT_KNOCK

	EVENT_END
	EVENT_DEBUG
	EVENT_INIT
	EVENT_SEND
	EVENT_SEND_NOW
	EVENT_INT_ERROR
	EVENT_CONNECTED
	EVENT_DISCONNECTED
	EVENT_RAW_IN
	EVENT_RAW_OUT
	EVENT_DO_ONE_LOOP
	EVENT_ONE_LOOP
	EVENT_GOT_PASSWORD
	EVENT_GOT_WRONG_PASSWORD
	EVENT_UNKNOWN


);

our $VERSION = '0.10';

# Preloaded methods go here.

# Variabler! --------------------------------------->
our $server; # server socket
our $select;
our %protocol;
our $handle_pingpong = 1; # Should the moduel handle server PING's?
our $connected = 0;
our $server_name = "net.ircservice";
our $server_comment = "Net::IRCService server $VERSION by Quai";
our $server_port = 6667;
our $server_addr;
our $server_passwd;
our $server_capab='TS3';
our $server_proto='Bahamut3';
our $DELTA = 0;
our %our_capab;
our %remote_capab;

our @ready;
our $inbuffer = '';
our $outbuffer = '';
our %signals;
our %timers;

our $timers=0;
our $status=0;
our $uid=getpwnam("nobody"); ## Set the prosess to nobody:nobody by default if its started by root(0).
our $gid=getgrnam("nobody");


my $STOP_SIGNAL = 0;
# <--------------------------------------------------

## Signaler!

sub EVENT_PRIVMSG       { 10; }  # Bahamut3, Hybrid6, Hybrid7
sub EVENT_WHOIS         { 20; }  # Bahamut3, Hybrid6, Hybrid7
sub EVENT_SNICK         { 30; }  # Bahamut3, Hybrid6, Hybrid7
sub EVENT_CNICK         { 35; }  # Bahamut3, Hybrid6, Hybrid7
sub EVENT_SERVER        { 40; }  # Bahamut3, Hybrid6, Hybrid7
sub EVENT_STOPIC        { 50; }  # Bahamut3
sub EVENT_CTOPIC        { 55; }  # Bahamut3, Hybrid6, Hybrid7
sub EVENT_INVITE        { 60; }  # Bahamut3, Hybrid6, Hybrid7
sub EVENT_VERSION       { 70; }  # Bahamut3, Hybrid6, Hybrid7
sub EVENT_QUIT          { 80; }  # Bahamut3, Hybrid6, Hybrid7
sub EVENT_SQUIT         { 90; }  # Bahamut3, Hybrid6, Hybrid7
sub EVENT_KILL          { 100; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_ERROR         { 110; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_AWAY          { 120; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_PING          { 130; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_PONG          { 140; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_PASS          { 150; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_WALLOPS       { 160; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_ADMIN         { 170; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_NOTICE        { 180; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_GNOTICE       { 190; } # Bahamut3
sub EVENT_PART          { 200; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_MOTD          { 210; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_MODE          { 220; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_KICK          { 230; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_SVINFO        { 240; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_CAPAB         { 250; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_SSJOIN        { 260; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_CSJOIN        { 270; } # Bahamut3, Hybrid6, Hybrid7
sub EVENT_AKILL         { 280; } # Bahamut3
sub EVENT_RAKILL        { 290; } # Bahamut3
sub EVENT_SVSKILL	{ 300; } # Bahamut3
sub EVENT_GLOBOPS	{ 310; } # Bahamut3
sub EVENT_KNOCKLL	{ 320; } # Hybrid7
sub EVENT_OPERWALL	{ 330; } # Hybrid6, Hybrid7
sub EVENT_KNOCK		{ 340; } # Hybrid6

sub EVENT_END			{ 5000; }
sub EVENT_DEBUG			{ 5010; }
sub EVENT_INIT			{ 5020; }
sub EVENT_SEND			{ 5030; }
sub EVENT_SEND_NOW		{ 5040; }
sub EVENT_INT_ERROR		{ 5050; }
sub EVENT_CONNECTED		{ 5060; }
sub EVENT_DISCONNECTED		{ 5070; }
sub EVENT_RAW_IN		{ 5080; }
sub EVENT_RAW_OUT		{ 5090; }
sub EVENT_DO_ONE_LOOP		{ 5100; }
sub EVENT_ONE_LOOP		{ 5110; }
sub EVENT_GOT_PASSWORD		{ 5120; }
sub EVENT_GOT_WRONG_PASSWORD	{ 5130; }
sub EVENT_UNKNOWN		{ 5140; }

#<---------------------------------------------------


BEGIN {
        # Load needed modules, and trap the error if something is missing.
        foreach my $mod (qw(POSIX IO::Select IO::Socket Socket Fcntl) ) {
                eval "use ${mod};";
		die "Couldn't load $mod (not installed?)\n" if ($@ ne '');
        }
}

END {
	
	&send_event(EVENT_END, '');
	&irc_send_now("ERROR :Closing connection on program exit. (Is something wrong?)");
	$server->close if $connected;

}

sub init_service {

	my %args=@_;

	die "Needs a SERVER_NAME!\n" if (!defined($args{SERVER_NAME}));

	$server_name = $args{SERVER_NAME};
	$server_comment = $args{COMMENT} if (defined($args{COMMENT}));
	$server_addr = $args{LOCALADDR} if (defined($args{LOCALADDR}));
	$server_port = $args{LOCALPORT} if (defined($args{LOCALPORT}));
	$server_passwd = $args{PASSWORD} if (defined($args{PASSWORD}));
	$server_capab = $args{CAPAB} if (defined($args{CAPAB}));
	foreach (split(' ', $server_capab)) {
	   $our_capab{$_}=1;
	 }
	$server_proto = $args{PROTOCOL} if (defined($args{PROTOCOL}));

	if ($server_proto =~ /^bahamut3$/i) {
		require "Net/IRCService/Bahamut3.pm";
	} elsif ($server_proto =~ /^hybrid6$/i) {
		require "Net/IRCService/Hybrid6.pm";
	} elsif ($server_proto =~ /^hybrid7$/i) {
		require "Net/IRCService/Hybrid7.pm";
	} else {
		die "Unknown IRCD protocol! ($server_proto)\n";
	}

	if ($<==0) {
		$uid = $args{UID} if (defined($args{UID}));
		$gid = $args{GID} if (defined($args{GID}));
		$>=$uid;
		$)=$gid;
		&send_event(EVENT_DEBUG, "Running as root(0). Setting UID/GID to $uid : $gid");
	} else {
		$uid = $<;
		$gid = $(;
		&send_event(EVENT_DEBUG, "Cant sent uid/gid! (not running as root(0))");
	}

	$server = IO::Socket::INET->new(        LocalPort => $server_port,
                                        LocalAddr => $server_addr,
                                        Listen    => 1,
                                        Reuse     => 1)
	        or die "Cant make server: $@\n";

	$select=IO::Select->new($server);

	my $flags = fcntl($server, F_GETFL, 0) or die "Can't get flag... $!\n";
	
	fcntl($server, F_SETFL, $flags | O_NONBLOCK) or die "Can't make socket nonblocking: $!\n";

	&send_event(EVENT_INIT, '');
	&send_event(EVENT_DEBUG, 'Init done...');
	$STOP_SIGNAL=0;
}

sub send_event { 
	my ($sig, @argv)=@_; 
	foreach (@{$signals{$sig}}) {
		&{$_}(@argv) if defined(&{$_});
	}
}

sub add_event_handler { 
	push @{$signals{$_[0]}}, $_[1];
}

sub irc_send {
	my $data=shift;
	if (!$connected) {
		&send_event(EVENT_INT_ERROR, 'irc_send: not connected to irc server!\n');
		return 0;
	}

	$data=~ s/[\r\n]$//g;
	$outbuffer.=$data."\r\n";

	&send_event(EVENT_SEND, $data);
	$STOP_SIGNAL=0;
}

sub ircsend {
	my $data=shift;
	if (!$connected) {
		&send_event(EVENT_INT_ERROR, 'irc_send: not connected to irc server!\n');
		return 0;
	}

	$data=~ s/[\r\n]$//g;
	$outbuffer.=$data."\r\n";

	&send_event(EVENT_SEND, $data);
	$STOP_SIGNAL=0;
}


sub irc_send_now {
	if (!$connected) {
		&send_event(EVENT_INT_ERROR, 'irc_send_now: not connected to irc server!\n');
		return 0;
	}

	my $data=shift;
	my $out=$data;
	my @sockets;
	my ($socket, $rv);
	
	$data=~ s/[\r\n]//g;
	$data.="\r\n";

	while (length($data)) {
		foreach $socket ($select->can_write(1)) {
			while (length($data)>0) {
				$rv = $socket->send($data, 0);	
				substr($data,0,$rv)='';
			}	
		}
	}

	&send_event(EVENT_RAW_OUT, $out);
	&send_event(EVENT_SEND_NOW, $out);
	&send_event(EVENT_SEND, $out);
	&send_event(EVENT_DEBUG, "irc_send_now: $out");
	$STOP_SIGNAL=0;
}

sub close_connection {
	my $msg=shift;
	&irc_send_now("ERROR :Closing Link: 0.0.0.0 $server_name (:$msg)");
	@ready=();
	$inbuffer='';
	$outbuffer='';
	$server->close if $connected;
	$status=0;
	$connected=0;
	&send_event(EVENT_DISCONNECTED, '');
}

sub do_one_loop {

	my ($client, $rv, $data);
        foreach $client ($select->can_read(0)) {
                        
                if ($client == $server) {
                        $client=$server->accept();
                        $select->add($client);
			my $flags = fcntl($client, F_GETFL, 0) or die "Can't get flag... $!\n";	
			fcntl($client, F_SETFL, $flags | O_NONBLOCK) or die "Can't make socket nonblocking: $!\n";
                        $status=1;
			$connected=1;

			my $oe=getpeername($client) or die ("Coundn't do getpeername");
			my $ip_addr = inet_ntoa((unpack_sockaddr_in($oe))[1]);

			&send_event(EVENT_DEBUG, 'do_one_loop: clientserver connected...');
			&send_event(EVENT_CONNECTED, $ip_addr);

                } else {           
		   
                        $data='';
                        $rv = $client->recv($data, POSIX::BUFSIZ, 0);
                        
                        unless(defined($rv) && length $data) {
                                @ready=();
                                $inbuffer='';
                                $outbuffer='';
                                $select->remove($client);
                                $status=0;
                                $client->close;
				$connected=0;
				&send_event(EVENT_DISCONNECTED, '');

                                next;
                        }
                 
                        $inbuffer.=$data;

                        while ($inbuffer=~s/^(.*?)\r?\n//) {
                                push @ready, $1;
				&send_event(EVENT_RAW_IN, $1);
                        }
                }
        }

        while (my $line=shift @ready) {
		chomp($line);
		if (($handle_pingpong == 1) && ($line =~ /^PING :(.*)$/)) {
			&irc_send_now(":$server_name PONG :$1");
                }        
		if ($status<=2) {
			handle_connect($line);
		}
		&parse_line($line);
        }
        foreach $client ($select->can_write(0)) {
                next if (length($outbuffer) == 0);
                
                $rv = $client->send($outbuffer, 0);
                unless (defined $rv) {
                        &send_event(EVENT_INT_ERROR, "I was told i coud write.. :(");
                        next;
                }

		&send_event(EVENT_RAW_OUT, $_) foreach split ("\r\n", $outbuffer);

                        
                if ($rv==length $outbuffer || $! == POSIX::EWOULDBLOCK) {
                        substr($outbuffer,0,$rv)='';
                } else {
                        $inbuffer='';
                        $outbuffer='';
                        @ready=();      
                        $select->remove($client);
                        $client->close;
			$connected=0;
			&send_event(EVENT_DISCONNECTED, '');
                        next;
                }
                        
        }
}

sub main_loop {
	while (1) {
		select(undef,undef,undef, 0.2);
		&do_one_loop;
		&send_event(EVENT_DO_ONE_LOOP, '');
		foreach (keys %timers) {
			if (time >= $timers{$_}{timeout}) {
				&{ $timers{$_}{sub} };
				del_timer($_);
			}
		}
	}
}

sub add_timer {
	my $timeout = shift;
	my $sub = shift;
	$timeout+=time;
	$timers++;
	$timers{"$timers"}{'sub'}=$sub;
	$timers{"$timers"}{'timeout'}=$timeout;
	return $timers;
}

sub del_timer { delete($timers{$_[0]}); }


sub handle_connect {
        
        my $line=shift;
        return if ($line =~ /${$protocol{NOTICE}}[3]/);
                        
        if ($line =~ /${$protocol{PASS}}[3]/) {
                if ($1 eq $server_passwd) {
			&send_event(EVENT_GOT_PASSWORD, $1);
			&irc_send_now("PASS $server_passwd :TS");
                        return;
                } else {
			&send_event(EVENT_GOT_WRONG_PASSWORD, $1);
                        @ready=();
                        $inbuffer='';
                        $outbuffer='';
                        $select->remove($server);
                        $status=0;
                        $server->shutdown;
			&send_event(EVENT_DISCONNECTED, '');
                        return;
                }

        }
        if ($line =~ /${$protocol{CAPAB}}[3]/) {
	        if ($line =~ /^CAPAB :(.*?)$/) {
		   foreach (split(' ', $1)) {
		      $remote_capab{$_}=1;
		   }
	        }
                &irc_send_now("CAPAB :$server_capab");
		
                return;
        }

        if ($line =~ /${$protocol{SERVER}}[3]/) {
		&irc_send_now("SERVER $server_name 1 :$server_comment");
                $status=2;
                return;
        }
        if ($line =~ /${$protocol{SVINFO}}[3]/) {
		$status=3;
                if ($3==0) {
                        $DELTA=$4-time;
                } else {
                        $DELTA=($4-time)/2;
                }
		&send_event(EVENT_DEBUG, "SVINFO: Time delta: $DELTA sec."); 
        }
	             
}


sub parse_line {
	my $line = shift;

	foreach (keys %protocol) {
		my @temp=@{$protocol{$_}};

		# 0 Reservert
		# 1 Nr. Args
		# 2 Event number
		# 3 Regexp

		my $regexp=$temp[3];
		$regexp=~ s/^(S_|C_)//;

		if ($line =~ /$temp[3]/) {
			my @arg;
			push @arg, ${$_} foreach (1..$temp[1]);
			&send_event($temp[2], @arg);
			return;
		}

	}

	&send_event(EVENT_UNKNOWN, $line);

}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::IRCService - Perl extension for creating a irc services for:

        o ircd-hybrid-6.3.1
        o ircd-hybrid-7rc3
        o bahamut-1.4.33

=head1 SYNOPSIS

  use Net::IRCService;
  
  &init_service(
	SERVER_NAME => 'services.network.no',
	LOCALADDR => '10.0.0.1',
	LOCALPORT => 7110,
	COMMENT => 'Services for network.no',
	PROTOCOL => 'Hybrid6',
	CAPAB => 'QS EX');

  &main_loop;


=head1 DESCRIPTION

Net::IRCService is suposed to be a easy interface to create more or
less usefull IRC-Services. If you have worked with Net::IRC before,
you will fast get to grip on how this module works. It has -almost- the
same event-driven interface. It lets you add one or more event handlers
to EVENTS seen by the module.

=head2 Functions

=head3 init_service()

This functions prepares the module. This must be run before &do_one_loop and/or
&main_loop.

Parameters;

   SERVER_NAME	  The server name. Must match the servernameyou use in the C/N's lines on the hub.
   COMMENT	  This comment will show up in /links.
   LOCALADDR	  The local ip/host to bind the server to.
   LOCALPORT	  The local port to listen on.
   PASSWORD	  The link password.
   CAPAB	  The content of the CAPAB line. Read the ircd source to understand this.
   PROTOCOL	  This tell the module witch protocol to use. (Hybrid6, Hybrid7 or Bahamut3).
										       
=head3 close_connection()

Close the uplink connection with a message;

   &close_connection("Something is wrong");

&add_event_handler

&do_one_loop
&main_loop

&add_timer
&del_timer

&irc_send
&irc_send_now

%remote_capab
%our_capab


												
=head3 add_event_handler

=head1 AUTHOR

Kay Sindre Bærulfsen, E<lt>kaysb@uten.netE<gt>

=head1 SEE ALSO

L<perl>.

=cut
