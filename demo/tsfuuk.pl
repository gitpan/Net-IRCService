#!/usr/bin/perl
use Net::IRCService;
use Net::IRCService::DB;

#
# Public domain, do what ever you whant with this, just dont blame me
# Kay Bærulfsen <kaysb @ uten . net>
#


my $irc = Net::IRCService::DB->new();
my $users_sendt=0;

my $server = 'tsfuuk.services.eu';
my $snick = 'TSFuuk';
&init_service(
   SERVER_NAME => $server,
   LOCALADDR => '192.168.1.100',
   LOCALPORT => 1800,
   PASSWORD => 'link',
   CAPAB   => 'QS',
   PROTOCOL => 'hybrid6');

$irc->init;


&add_event_handler(EVENT_SNICK, \&send_users);
sub send_users {
   return if ($users_sendt);
   my $ts=time;
   &irc_send("NICK $snick 1 $ts +oi $snick $server $server :$snick");
   $users_sendt=1;
}

&add_event_handler(EVENT_PRIVMSG, \&event_privmsg);
sub event_privmsg {
   my ($from, $target, $data) = @_;

   return 0 if (!$irc->is_oper($from));

   if ($target !~ /^#/) {
      
      if ($irc->_lc($target) eq $irc->_lc($snick)) {
	 
	 if ($data =~ /^TSFUUK (#[^ ]+)$/i) {
	    
	    my $channel = $1;
	    
	    if ($irc->channel_exists($channel) {
	       
	       if (!$irc->is_member($from, $channel)) {
		  
		  &irc_send(":$snick NOTICE $from :You are not on that channel.");
		  return;
		  
	       }

	       my $ts = $irc->get_channel_ts($channel);

	       if ($ts == 0) {
		  
		  &irc_send(":$snick NOTICE $from :$channels has a TS of 0, nothing I can do.");
		  return;
		  
	       }

	       if (!$irc->channel_set_ts($channel, $ts-1)) {
		  
		  &irc_send(":$snick NOTICE $from :Could not tsfuuk $channel");
		  return;
		  
	       }
	       
	       &irc_send(sprintf(":%s SJOIN %s %s + :%s", $server, $ts-1, $channel, $snick));
	       $irc->op($snick, $channel, $from);
	       &irc_send(":$nick PART $channel");
	       
	    } else {
	       
	       &irc_send(":$snick NOTICE $from :Channel $channel does not exists.");
	       return;
	       
	    }
	    
	 }
	 
      }
      
   }
   
}


&main_loop;
	    
	    

