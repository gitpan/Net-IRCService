#
# Net::IRCService (Bahamut3.pm)
# Copyright (C) 2001  Kay Sindre Baerulfsen
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


#
# "Mental note":
#
#	I dont have everything in the Bahamut protocol here, and I really need to
#	find out the syntax for akills and zlines and so on. Ill use the include/msg.h
#	file to see witch commands I am missing. (Added support for akills and rakill I
#	THINK. Yet to test :P)
#

push @EXPORT, qw(
	&send_whois
	);

our %protocol=(

        #define MSG_PRIVATE  "PRIVMSG"  /* PRIV */
        PRIVMSG => [0, 3, EVENT_PRIVMSG,'^:(.*?) PRIVMSG (.*?) :(.*?)$'],

        #define MSG_WHOIS    "WHOIS"    /* WHOI */
        WHOIS   => [0, 3, EVENT_WHOIS,  '^:(.*?) WHOIS (.*?) :(.*?)$'],

        #define MSG_NICK     "NICK"     /* NICK */
	#Bahamuts NICK is somewhat different from Hybrid's, (the numbers on the end)
        S_NICK  => [0, 10, EVENT_SNICK, '^NICK (.*?) (\d+) (\d+) (\+.*?) (.*?) (.*?) (.*?) (\d+) :(.*?)$'],
        C_NICK  => [0, 3, EVENT_CNICK,  '^:(.*?) NICK (.*?) :(\d+)$'],

        #define MSG_SERVER   "SERVER"   /* SERV */
        SERVER  => [0, 4, EVENT_SERVER, '^(?::(.*?) |)SERVER (.*?) (\d+) :(.*?)$'],

        #define MSG_TOPIC    "TOPIC"    /* TOPI */
	# Bahamut sends a TOPIC burst on connect. 
        S_TOPIC => [0, 5, EVENT_STOPIC,  '^:(.*?) TOPIC (.*?) (.*?) (\d+) :(.*?)$'],
        C_TOPIC => [0, 3, EVENT_CTOPIC,  '^:(.*?) TOPIC ([^ ]+) :(.*?)$'],

        #define MSG_INVITE   "INVITE"   /* INVI */
        INVITE  => [0, 3, EVENT_INVITE, '^:(.*?) INVITE (.*?) :(.*?)$'],

        #define MSG_VERSION  "VERSION"  /* VERS */
        VERSION => [0, 2, EVENT_VERSION,'^:(.*?) VERSION :(.*?)$'],

        #define MSG_QUIT     "QUIT"     /* QUIT */
        QUIT    => [0, 2, EVENT_QUIT,   '^:(.*?) QUIT :(.*?)$'],

        #define MSG_SQUIT    "SQUIT"    /* SQUI */
        SQUIT   => [0, 3, EVENT_SQUIT,  '^:?(.*?)? ?SQUIT (.*?) :(.*?)$'],

        #define MSG_KILL     "KILL"     /* KILL */
        KILL    => [0, 4, EVENT_KILL,   '^:(.*?) KILL (.*?) :(.*?) \((.*?)\)$'],

        #define MSG_ERROR    "ERROR"    /* ERRO */
        ERROR   => [0, 1, EVENT_ERROR,  '^ERROR :(.*?)$'],

        #define MSG_AWAY     "AWAY"     /* AWAY */
        AWAY    => [0, 2, EVENT_AWAY,   '^:(.*?) AWAY :(.*?)$'],

        #define MSG_PING     "PING"     /* PING */
        PING    => [0, 1, EVENT_PING,   '^PING :(.*?)$'],

        #define MSG_PONG     "PONG"     /* PONG */
        PONG    => [0, 3, EVENT_PONG,   '^:(.*?) PONG (.*?) :(.*?)$'],

        #define MSG_PASS     "PASS"     /* PASS */
        PASS    => [0, 1, EVENT_PASS,   '^PASS (.*?) :TS$'],

        #define MSG_WALLOPS  "WALLOPS"  /* WALL */
        WALLOPS => [0, 2, EVENT_WALLOPS,'^:(.*?) WALLOPS :(.*?)$'],

        #define MSG_ADMIN    "ADMIN"    /* ADMI */
        ADMIN   => [0, 2, EVENT_ADMIN,  '^:(.*?) ADMIN :(.*?)$'],
        
        #define MSG_NOTICE   "NOTICE"   /* NOTI */
        NOTICE  => [0, 3, EVENT_NOTICE, '^:(.*?) NOTICE\s*(.*?)\s*:(.*)$'],
        GNOTICE => [0, 2, EVENT_GNOTICE,'^:(.*?) GNOTICE :(.*?)$'],
 
        #define MSG_PART     "PART"     /* PART */
        PART    => [0, 2, EVENT_PART,   '^:(.*?) PART (.*?)$'],
        
        #define MSG_MOTD     "MOTD"     /* MOTD */
        MOTD    => [0, 2, EVENT_MOTD,   '^:(.*?) MOTD :(.*?)$'],
        
        #define MSG_MODE     "MODE"     /* MODE */
        MODE    => [0, 3, EVENT_MODE,   '^:(.*?) MODE (.*?) (.*?)$'],

        #define MSG_KICK     "KICK"     /* KICK */
        KICK    => [0, 4, EVENT_KICK,   '^:(.*?) KICK (.*?) (.*?) :(.*?)$'],
        
        #define MSG_SVINFO   "SVINFO"   /* SVINFO */
        SVINFO  => [0, 4, EVENT_SVINFO, '^SVINFO (\d+) (\d+) (\d+) :(\d+)$'],
        
        #define MSG_SJOIN    "SJOIN"    /* SJOIN */
        S_SJOIN => [0, 5, EVENT_SSJOIN, '^:(.*?) SJOIN (\d+) (.*?) (\+.*?) :(.*?)$'],
        C_SJOIN => [0, 3, EVENT_CSJOIN, '^:(.*?) SJOIN (\d+) ([^ ]+)$'],
        
        #define MSG_CAPAB    "CAPAB"    /* CAPAB */
        CAPAB   => [0, 1, EVENT_CAPAB,  '^CAPAB (.*?)$'],

	# send_cmd(NULL, "AKILL %s %s %d %s %ld :%s", host, user, 86400*2, who, when, reason);
	AKILL	=> [0, 6, EVENT_AKILL,	'^AKILL (.*?) (.*?) (\d+) (.*?) (.*?) :(.*?)$'],

	# send_cmd(NULL, "RAKILL %s %s", host, user);
	RAKILL	=> [0, 2, EVENT_RAKILL,	'^RAKILL (.*?) (.*)$'],

	# send_cmd(NULL, "SVSKILL %s :%s", u->nick, reason);
	SVSKILL	=> [0, 2, EVENT_SVSKILL,'^SVSKILL (.*?) :(.*?)$'],        

	# send_cmd(source ? source : ServerName, "GLOBOPS :%s", buf);
	GLOBOPS	=> [0, 2, EVENT_GLOBOPS,'^:(.*?) GLOBOPS :(.*?)$'],
);

sub send_whois {

	my %args=@_;

        my $server_name=$Net::IRCService::server_name;
        my $server_comment=$Net::IRCService::server_comment;


	$args{IDLE}=int(rand(1000))+1 if (!defined($args{IDLE}));
	$args{SIGNON}=time-int(rand(1000)) if ((!defined($args{SIGNON}))||($args{SIGNON}==0));
        
        &irc_send(":$server_name 311 $args{TARGET} $args{NICK} $args{IDENT} $args{HOST} * :$args{REALNAME}");
        &irc_send(":$server_name 319 $args{TARGET} $args{NICK} :$args{CHANNELS}");
        &irc_send(":$server_name 312 $args{TARGET} $args{NICK} $server_name :$server_comment");
        &irc_send(":$server_name 301 $args{TARGET} $args{NICK} :$args{AWAY}") if ($args{AWAY} ne '');
        &irc_send(":$server_name 313 $args{TARGET} $args{NICK} :is an IRC Operator") if (!$args{OPER});
        &irc_send(":$server_name 317 $args{TARGET} $args{NICK} $args{IDLE} $args{SIGNON} :seconds idle, signon time");
        &irc_send(":$server_name 318 $args{TARGET} $args{NICK} :End of /WHOIS list.");
}

sub send_motd { ## send_motd (nick, array_with_motd)
        my $server_name=$Net::IRCService::server_name;
	my %args = @_;
        &irc_send(":$server_name 375 $args{TARGET} :- $server_name Message of the day - ");
        &irc_send(":$server_name 372 $args{TARGET} :- $_") foreach (@{ $args{MOTD} });
        &irc_send(":$server_name 376 $args{TARGET} :- End of /MOTD command");
}

sub send_no_motd {
        my $server_name=$Net::IRCService::server_name;
        my %args = @_;
        &irc_send(":$server_name 422 $args{TARGET} :MOTD File is missing");
}

sub send_version {
        my $server_name=$Net::IRCService::server_name;
	my %args = @_;
        &irc_send(":$server_name 351 $args{TARGET} $args{VERSION} $server_name :$args{COMMENT}");
}

sub send_admin {
        my $server_name=$Net::IRCService::server_name;
	my %args = @_;
        &irc_send(":$server_name 256 $args{TARGET} $server_name :Administrative info");
        &irc_send(":$server_name 257 $args{TARGET} :$args{ADDR1}");
        &irc_send(":$server_name 258 $args{TARGET} :$args{ADDR2}");
        &irc_send(":$server_name 259 $args{TARGET} :$args{EMAIL}");
}
        
sub send_no_admin {  
        my $server_name=$Net::IRCService::server_name;
	my %args = @_;
        &irc_send(":$server_name 423 $args{TARGET} $server_name :No administrative info available");
}

sub send_nick {
        my $server_name=$Net::IRCService::server_name;
	my %args = @_;
	&irc_send("NICK $args{NICK} 1 $args{TS} $args{MODE} $args{IDENT} $args{HOST} $server_name 0 :$args{REALNAME}");
}


#/*
# * m_nick
# * parv[0] = sender prefix
# * parv[1] = nickname
# * parv[2] = hopcount when new user; TS when nick change
# * parv[3] = TS
# * ---- new user only below ----
# * parv[4] = umode
# * parv[5] = username
# * parv[6] = hostname
# * parv[7] = server
# * parv[8] = serviceid
# * -- If NICKIP
# * parv[9] = IP
# * parv[10] = ircname
# * -- else
# * parv[9] = ircname
# * -- endif
# */
# NICK root 1 1031846515 +oiwh root www.juvente.nu irc.kirkevik.no 0 :-
