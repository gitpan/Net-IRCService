#!/usr/bin/perl
use Net::IRCService;

#
# Public domain, do what ever you whant with this, just dont blame me
# Kay Bærulfsen <kaysb @ uten . net>
#

my $users_sendt=0;

my $server = 'wallrelay.services.eu';
my $operwall_nick = 'OPERWALL';
my $wallops_nick = 'WALLOPS';
my $channel = '#wallrelay';

# NB! Wallops should NOT be relayed to normal users. This is just an example to
# show what you can do with this module.


&init_service(
   SERVER_NAME => $server,
   LOCALADDR => '192.168.1.100',
   LOCALPORT => 1800,
   PASSWORD => 'link',
   CAPAB   => 'QS',
   PROTOCOL => 'hybrid6');


&add_event_handler(EVENT_SNICK, \&send_users);
sub send_users {
   return if ($users_sendt);
   my $ts=time;
   &irc_send("NICK $operwall_nick 1 $ts +oiw $operwall_nick $server $server :OPERWALL relay client");
   &irc_send("NICK $wallops_nick 1 $ts +oiw $wallops_nick $server $server :WALLOPS relay client");
   &irc_send(":$server SJOIN $ts $channel + :$operwall_nick $wallops_nick");
   $users_sendt=1;
}

&add_event_handler(EVENT_WALLOPS, \&wallops);
sub wallops {
   return if (!$users_sendt);
   my ($from, $msg) = @_;
   &irc_send(":$wallops_nick PRIVMSG $channel :$from - $msg");
}

&add_event_handler(EVENT_OPERWALL, \&operwall);
sub operwall {
   return if (!$users_sendt);
   my ($from, $msg) = @_;
   &irc_send(":$operwall_nick PRIVMSG $channel :$from - $msg");
}


&main_loop;
