#
# Net::IRCService (Hybrid7.pm)
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



our %protocol=(

        #define MSG_PRIVATE  "PRIVMSG"  /* PRIV */
        PRIVMSG => [0, 3, EVENT_PRIVMSG,'^:(.*?) PRIVMSG (.*?) :(.*?)$'],

        #define MSG_WHOIS    "WHOIS"    /* WHOI */
        WHOIS   => [0, 3, EVENT_WHOIS,  '^:(.*?) WHOIS (.*?) :(.*?)$'],

        #define MSG_NICK     "NICK"     /* NICK */
        S_NICK	=> [0, 9, EVENT_SNICK, '^NICK (.*?) (\d+) (\d+) (\+.*?) ([^ ]+) ([^ ]+) ([^ ]+) :(.*?)$'],
        C_NICK  => [0, 3, EVENT_CNICK,  '^:(.*?) NICK (.*?) :(\d+)$'],

        #define MSG_SERVER   "SERVER"   /* SERV */
	SERVER  => [0, 4, EVENT_SERVER, '^(?::(.*?) |)SERVER (.*?) (\d+) :(.*?)$'],

        #define MSG_TOPIC    "TOPIC"    /* TOPI */
	# Hybnet dosnt send any TOPIC burst at connect. So the S_TOPIC will be unused. 
        S_TOPIC => [0, 0, EVENT_STOPIC,  '^unused$'],
        C_TOPIC => [0, 3, ECENT_CTOPIC,  '^:(.*?) TOPIC ([^ ]+) :(.*?)$'],

        #define MSG_INVITE   "INVITE"   /* INVI */
        INVITE  => [0, 3, EVENT_INVITE, '^:(.*?) INVITE (.*?) :(.*?)$'],

        #define MSG_VERSION  "VERSION"  /* VERS */
        VERSION => [0, 2, EVENT_VERSION,'^:(.*?) VERSION :(.*?)$'],

        #define MSG_QUIT     "QUIT"     /* QUIT */
        QUIT    => [0, 2, EVENT_QUIT,   '^:(.*?) QUIT :(.*?)$'],

        #define MSG_SQUIT    "SQUIT"    /* SQUI */
        SQUIT   => [0, 2, EVENT_SQUIT,  '^SQUIT (.*?) :(.*?)$'],

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

	# I dont know if Hybrid uses GNOTICE, Ill check this out now...  I was right, so, lets comment it out
        # GNOTICE => [0, 2, EVENT_GNOTICE,'^:(.*?) GNOTICE :(.*?)$'],
 
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

	# :%s KNOCKLL %s %s %s
	KNOCKLL => [0, 3, EVENT_KNOCKLL,'^:(.*?) KNOCKLL (.*?) (.*?) (.*?)$']
);

1;
