package Net::IRCService::DB;

#
# Net::IRCService::DB
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

use Carp;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = '0.13';

my (%users, %channels, %servers);

sub new {
   my $class = shift;
   my $self;
   $self->{_INIT}=0;

   croak "ERROR: Cant live without Net::IRCService!" if (!defined($Net::IRCService::VERSION));

   bless ($self, $class);
   return $self;
}

sub init {
   my $self = shift;
   croak "ERROR: init must be called after Net::IRCService::init_service!" if (!defined($Net::IRCService::server));

   &Net::IRCService::add_event_handler(Net::IRCService::EVENT_SSJOIN, \&Net::IRCService::DB::_event_sjoin);
   &Net::IRCService::add_event_handler(Net::IRCService::EVENT_QUIT, \&Net::IRCService::DB::_event_quit);
   &Net::IRCService::add_event_handler(Net::IRCService::EVENT_KILL, \&Net::IRCService::DB::_event_kill);
   
   &Net::IRCService::add_event_handler(Net::IRCService::EVENT_PART, \&Net::IRCService::DB::_event_part);
   &Net::IRCService::add_event_handler(Net::IRCService::EVENT_KICK, \&Net::IRCService::DB::_event_kick);
   
   &Net::IRCService::add_event_handler(Net::IRCService::EVENT_MODE, \&Net::IRCService::DB::_event_mode);
   
   &Net::IRCService::add_event_handler(Net::IRCService::EVENT_SNICK, \&Net::IRCService::DB::_event_snick);
   &Net::IRCService::add_event_handler(Net::IRCService::EVENT_CNICK, \&Net::IRCService::DB::_event_cnick);

   &Net::IRCService::add_event_handler(Net::IRCService::EVENT_SERVER, \&Net::IRCService::DB::_event_server);
   &Net::IRCService::add_event_handler(Net::IRCService::EVENT_SQUIT, \&Net::IRCService::DB::_event_squit);
   
}

sub _event_server {
   my ($from, $server, $jumps, $comment) = @_;
   my $lc_serv = lc($server);

   $servers{"$lc_serv"}{'uplink'} = $from;
   $servers{"$lc_serv"}{'server'} = $server;
   $servers{"$lc_serv"}{'jumps'} = $jumps;
   $servers{"$lc_serv"}{'comment'} = $comment;
}

sub _event_squit {
   my ($server, $hub) = @_;
   my $lc_serv = lc($server);
   
   delete($servers{"$lc_serv"});

   ## Should I delete all knowns clients from this server here?
   ##  - Not unless we enable CAP_QS! :)
   
   if ($Net::IRCService::our_capab{'QS'} == 1) {
      foreach (keys %users) {
	 next if ($_ =~ /^\./);
	 if ($users{"$_"}{'server'} eq $lc_serv) {
	    &_event_quit($_, "Netsplit: $server <-> $hub");
	 }
      }
   }

}

sub _event_kick {
   my ($from, $chan, $target, $reason) = @_;
   &_event_part($target, $chan);
}

sub _event_kill {
   my ($from, $target, $code, $reason) = @_;
   &_event_quit($target, "Killed: $reason");
}

sub _event_sjoin {
   my ($from, $ts, $channel, $mode, $users) = @_;

   my $lc_chan = lc($channel);

   if (!exists($channels{"$lc_chan"}{'ts'})) {
      # Kanalen ekisterer ikke
      $channels{"$lc_chan"}{'ts'}=$ts;
      $channels{"$lc_chan"}{'topic'}{'ts'}=1;
      $channels{"$lc_chan"}{'topic'}{'topic'}='';
      $channels{'.channels'}++;
   }
      
   foreach (split(' ', $users)) {
      my $lc_nick=_lc($_);

      my $op = ($lc_nick =~ s/\@// ? 1 : 0);
      my $voice = ($lc_nick =~ s/\+// ? 1 : 0);
      my $halfop = ($lc_nick =~ s/\%// ? 1 : 0);
	 
      # Første bokstaven i et nick er en bokstav, sørg for at det ikke er noe fremmedlegmer før det.
      # (Remove modes that I dont understand. (A nick starts with a alphachar))
      $lc_nick =~ s/^[^a-z]+//i;

      $channels{"$lc_chan"}{'users'}{"$lc_nick"}{'op'}= $op;
      $channels{"$lc_chan"}{'users'}{"$lc_nick"}{'voice'}= $voice;

      $users{"$lc_nick"}{'channels'}{"$lc_chan"}=($op?'@':'').($voice?'+':'').($halfop?'%':'');
   }

   return if ($mode eq '0');

   my $add=0;
   $mode =~ s/^([^ ]+)//;
   my $modes = $1;
   $mode =~ s/^\s+//;

   my $m;
   foreach $m (split('',$modes)) {
      next if ($m eq '');
      if ($m =~ /\+/) { $add=1; next; }
      if ($m =~ /-/) { $add=0; next; }
      if ($add) {
	 $channels{"$lc_chan"}{'mode'}.=$m;
	 if ($m =~ /k/) {
	    $mode =~ s/^([^ ]+)//;
	    $channels{"$lc_chan"}{'key'}=$1;
	    $mode =~ s/^\s+//;
	 } elsif ($m =~ /l/) {
	    $mode =~ s/^([^ ]+)//;
	    $channels{"$lc_chan"}{'limit'}=$1;
	    $mode =~ s/^\s+//;
	 }
      } else {
	 if (exists($channels{"$lc_chan"}{'mode'})) {
	    $channels{"$lc_chan"}{'mode'} =~ s/$m//g;
	 } else {
	    $channels{"$lc_chan"}{'mode'} = '';
	 }
	 if ($m =~ /k/) {
	    $channels{"$lc_chan"}{'key'}='';
	 } elsif ($m =~ /l/) {
	    $channels{"$lc_chan"}{'limit'}=-1;
	 }
      }
   }
}

sub _event_part {
   my ($nick, $channel) = @_;
   my $lc_nick = _lc($nick);
   my $lc_chan = lc($channel);
   delete($channels{"$lc_chan"}{'users'}{"$lc_nick"});
   delete($users{"$lc_nick"}{'channels'}{"$lc_chan"});

   if (scalar(keys(%{$channels{"$lc_chan"}{'users'}})) == 0) {
      delete($channels{"$lc_chan"});
      $channels{'.channels'}--;
   }
}

sub _event_quit {
   my ($nick, $reason) = @_;
   my $lc_nick = _lc($nick);
   my $lc_serv = _lc($users{"$lc_nick"}{'server'});
   
   $users{'.users'}--;

   foreach (keys %{$users{"$lc_nick"}{'channels'}}) {
      delete($channels{"$_"}{'users'}{"$lc_nick"});
      if (scalar(keys(%{$channels{"$_"}{'users'}})) == 0) {
	 delete($channels{"$_"});
	 $channels{'.channels'}--;
      }
   }

   delete($users{"$lc_nick"});

}

sub _event_cnick {
   my ($old, $new, $ts) = @_;
   my $lc_old = _lc($old);
   my $lc_new = _lc($new);
   my $lc_serv = _lc($users{"$lc_old"}{'server'});

   %{$users{"$lc_new"}}=%{$users{"$lc_old"}};
   
   foreach (keys %{$users{"$lc_old"}}) {
      $users{"$lc_new"}{"$_"}=$users{"$lc_old"}{"$_"};
      delete($users{"$lc_old"}{"$_"});
   }
   delete($users{"$lc_old"});
   $users{"$lc_new"}{'nick'}=$new;
   $users{"$lc_new"}{'ts'}=$ts;

   $users{'.users'}--;
}
				       


sub _event_mode {
   my ($from, $target, $mode)=@_;

   if ($target =~ /^#/) {
      # channel mode!
      my $add=1;
      my $lc_chan = lc($target);
      my @items = split(' ', $mode);
      my $modes = shift @items;
      foreach (split('', $modes)) {
	 if (/\+/) { $add=1; next; } elsif (/-/) { $add=0; next; }
	 if ($add) {
	    if (/o/) {
	       my $lc_nick = _lc(shift @items);
	       my $lc_chan = lc($target);
	       $channels{"$lc_chan"}{'users'}{"$lc_nick"}{'op'}=1;
	    } elsif (/v/) {
	       my ($lc_nick, $lc_chan) = (_lc(shift @items), lc($target));
	       $channels{"$lc_chan"}{'users'}{"$lc_nick"}{'voice'}=1;
            } elsif (/h/) {
               my ($lc_nick, $lc_chan) = (_lc(shift @items), lc($target));
               $channels{"$lc_chan"}{'users'}{"$lc_nick"}{'halfop'}=1;
	    } elsif (/l/) {
	       my $lc_chan = lc($target);
	       $channels{"$lc_chan"}{'limit'}=shift @items;
	    } elsif (/k/) {
	       my $lc_chan = lc($target);
	       $channels{"$lc_chan"}{'key'}=shift @items;
	    } elsif (/b/) {
	       # add ban
	       my ($lc_ban, $lc_chan) = (_lc(shift @items), lc($target));
	       $channels{"$lc_chan"}{'bans'}{"$lc_ban"}{'setby'}=$from;
	       $channels{"$lc_chan"}{'bans'}{"$lc_ban"}{'ts'}=time;
	    } else {
	       $channels{"$lc_chan"}{'modes'}.=$_;
	    }
	 } else {
	    if (/o/) {
	       my $lc_nick = _lc(shift @items);
	       my $lc_chan = lc($target);
	       if (exists($channels{"$lc_chan"}{'users'}{"$lc_nick"}{'op'})) {
		  delete($channels{"$lc_chan"}{'users'}{"$lc_nick"}{'op'});
	       }
	    } elsif (/v/) {
	       my ($lc_nick, $lc_chan) = (_lc(shift @items), lc($target));
	       if (exists($channels{"$lc_chan"}{'users'}{"$lc_nick"}{'voice'})) {
		  delete($channels{"$lc_chan"}{'users'}{"$lc_nick"}{'voice'});
	       }
            } elsif (/h/) {
               my ($lc_nick, $lc_chan) = (_lc(shift @items), lc($target));
               if (exists($channels{"$lc_chan"}{'users'}{"$lc_nick"}{'halfop'})) {
                  delete($channels{"$lc_chan"}{'users'}{"$lc_nick"}{'halfop'});
               }
	    } elsif (/l/) {
	       my $lc_chan = lc($target);
	       if (exists($channels{"$lc_chan"}{'limit'})) {
		  delete($channels{"$lc_chan"}{'limit'});
	       }
	    } elsif (/k/) {
	       my $lc_chan = lc($target);
	       if (exists($channels{"$lc_chan"}{'key'})) {
		  delete($channels{"$lc_chan"}{'key'});
	       }
	    } elsif (/b/) {
	       my ($lc_ban, $lc_chan) = (_lc(shift @items), lc($target));
	       if (exists($channels{"$lc_chan"}{'bans'}{"$lc_ban"}{'setby'})) {
		  delete($channels{"$lc_chan"}{'bans'}{"$lc_ban"}{'setby'});
		  delete($channels{"$lc_chan"}{'bans'}{"$lc_ban"}{'ts'});
		  delete($channels{"$lc_chan"}{'bans'}{"$lc_ban"});
	       }
	    } else {
	       $channels{"$lc_chan"}{'mode'}=~ s/$_//g;
	    }
	 }
      }
   } else {
      # user mode!
      my $add=1;
      my $lc_nick= _lc($target);
      foreach (split('', $mode)) {
	 if (/\+/) { $add=1; next; } elsif (/-/) { $add=0; next; }
	 if ($add) {
	    $users{"$lc_nick"}{'mode'}.=$_;
	 } else {
	    $users{"$lc_nick"}{'mode'}=~ s/$_//;
	 }
      }
   }      
}


sub _event_snick {
   my ($nick, $hops, $ts, $mode, $ident, $host, $server, $geco) = @_;
   
   my $lc_nick = _lc($nick);
   my $lc_serv = lc($server);
   $mode =~ s/^\+//;
   $users{"$lc_nick"}{'nick'}=$nick;
   $users{"$lc_nick"}{'hops'}=$hops;
   $users{"$lc_nick"}{'ts'}=$ts;
   $users{"$lc_nick"}{'mode'}=$mode;
   $users{"$lc_nick"}{'ident'}=$ident;
   $users{"$lc_nick"}{'host'}=$host;
   $users{"$lc_nick"}{'server'}=$server;
   $users{"$lc_nick"}{'geco'}=$geco;
   $users{'.users'}++;
}

sub _lc {
   my $nick = shift;
   $nick =~ tr/[]\\/{}|/;
   return lc($nick);
}
	 
###########################################################################
### USERS FUNCTIONS
###########################################################################

## Returnerer en hashref som inneholder alt hva modulen vet om et en user
# find_user($nick)
sub user_find {
   my ($self, $nick) = @_;
   $nick = _lc($nick);
   return \%{$users{"$nick"}};
}

## Eksisterer dette nicket?
# user_exists($nick)
sub user_exists {
   my ($self, $nick) = @_;
   $nick = _lc($nick);
   return exists($users{"$nick"});
}

sub channel_exists {
   my ($self, $channel) = @_;
   $channel = lc($channel);
   return exists($channels{"$channel"});
}
	 

## Er klienten IRC-operatør?
# is_oper($nick)
sub is_oper {
   my ($self, $nick) = @_;
   $nick = _lc($nick);
   return 1 if ($users{"$nick"}{'mode'} =~ /o/i);
   return 0;
}

sub is_member {
   my ($self, $nick, $channel) = @_;
   my $lc_nick = _lc($nick);
   my $lc_chan = _lc($channel);
   return exists($channels{"$lc_chan"}{'users'}{"$lc_nick"});
}

## returnerer en liste over alle brukere. FARLIG :P
# user_list
sub user_list {
   my $self = shift;
   my @list;
   foreach (keys %users) {
      next if (/^\./);
      push @list, $users{"$_"}{'nick'} if (exists($users{"$_"}{'nick'}));
   }
   return @list;
}

sub server_list {
   my $self = shift;
   return (keys %servers);
}

####################################

sub users {
   return $users{'.users'};
}

sub channels {
   return $channels{'.channels'};
}

sub servers {
   return scalar(keys(%servers));
}

sub has_op {
   my $self = shift;
   my $lc_nick = _lc(shift);
   my $lc_chan = lc(shift);
   return $channels{"$lc_chan"}{'users'}{"$lc_nick"}{'op'};
}

sub has_voice {
   my $self = shift;
   my $lc_nick = _lc(shift);
   my $lc_chan = lc(shift);
   return $channels{"$lc_chan"}{'users'}{"$lc_nick"}{'voice'};
}

sub has_halfop {
   my $self = shift;
   my $lc_nick = _lc(shift);
   my $lc_chan = lc(shift);
   return $channels{"$lc_chan"}{'users'}{"$lc_nick"}{'halfop'};
}

	    
sub channel_list {
   my $self = shift;
   my @l;
   foreach (keys(%channels)) {
      push @l, $_ if ($_ !~ /^\./);
   }
   return @l;
}

sub key {
   my $self = shift;
   my $lc_chan = lc(shift);
   my $from = _lc(shift);
   my $key = shift;
   if (defined($key)) {
      $channels{"$lc_chan"}{'key'}=$key;
      &Net::IRCService::ircsend(":$from MODE $lc_chan +k $key");
   }
   return $channels{"$lc_chan"}{'key'};
}

sub limit {
   my ($self, $channel, $from, $limit) = @_;
   my $lc_chan = lc($channel);
   if (defined($limit)) {
      $channels{"$lc_chan"}{'limit'}=$limit;
      &Net::IRCService::ircsend(":$from MODE $lc_chan +l $limit");
   }
   return $channels{"$lc_chan"}{'limit'};
}

#sub mode {
#   my $self=shift;
#   my $channel = shift;
#   my $from = shift;
#   my $mode = shift;
#   my $modes = @_;

sub channel_get_ts {
   my $self = shift;
   my $lc_chan = lc(shift);
   my $ts = $channels{"$lc_chan"}{'ts'};
   return $ts;
}

sub channel_set_ts {
   my $self=shift;
   my $lc_chan = lc(shift);
   my $ts = shift;
   $ts+=0;

   return 0 if ($channels{"$lc_chan"}{'ts'} <= $ts);

   foreach (keys %{ $channels{"$lc_chan"}{'users'} }) {
      $channels{"$lc_chan"}{'users'}{"$_"}{'op'} = 0;
      $channels{"$lc_chan"}{'users'}{"$_"}{'voice'} = 0;
      $channels{"$lc_chan"}{'users'}{"$_"}{'halfop'} = 0;
   }

   foreach (keys %{ $channels{"$lc_chan"}{'bans'} }) {
      delete($channels{"$lc_chan"}{'bans'}{"$_"});
   }

   $channels{"$lc_chan"}{'limit'}=-1;
   $channels{"$lc_chan"}{'key'}='';
   $channels{"$lc_chan"}{'mode'}='';

   $channels{"$lc_chan"}{'ts'}=$ts;
}
   


sub channel_get_users {
   my $self = shift;
   my $lc_chan = lc(shift);
   my @users;
   if (exists($channels{"$lc_chan"})) {
      foreach (keys %{ $channels{"$lc_chan"}{'users'} }) {
	 push @users, $_;
      }
      return @users;
   }
   return 0;
}

###########################################################################
# IRC Commands, sends the command to the server, and update the "DB"
###########################################################################

sub kill {
   my ($self, $from, $nick, $reason) = @_;
   my $lc_from  = _lc($from);
   my $serv     = $users{$lc_from}{'server'};
   my $host     = $users{$lc_from}{'host'};
   my $ident    = $users{$lc_from}{'ident'};
   my $code = join '!', $serv, $host, $ident, $from;

   &Net::IRCService::ircsend(":$from KILL $nick :$code ($reason)");
   &_event_kill($from, $nick, undef, $reason);
}

sub kick {
   my ($self, $from, $nick, $channel, $reason) = @_;
   &Net::IRCService::ircsend(":$from KICK $channel $nick :$reason");
   &_event_part($nick, $channel);
}

sub _multimodes {
   my ($from, $channel, $mode) = (shift, shift, shift);
   my @nicks = @_;
   my $count=0;
   my $modes;
   my $nicks;
   $mode =~ /(.)(.)/;
   my $prefix = $1;
   $mode = $2;
   foreach (@nicks) {
      $modes.=$mode;
      $nicks.=" $_";
      $count++;
      if ($count == 4) {
	 $nicks =~ s/^\s+//;
	 &Net::IRCService::ircsend(":$from MODE $channel ${prefix}$modes $nicks");
	 &_event_mode($from, $channel, "${prefix}$modes $nicks");
	 $modes='';
	 $nicks='';
	 $count=0;
      }
   }
   if ($count > 0) {
      $nicks =~ s/^\s+//;
      &Net::IRCService::ircsend(":$from MODE $channel ${prefix}$modes $nicks");
      &_event_mode($from, $channel, "${prefix}$modes $nicks");
   }
}

sub op {
   my ($self, $from, $channel) = (shift, shift, shift);
   my @nicks = @_;
   &_multimodes($from, $channel, '+o', @nicks);
}
	 
sub deop {
   my ($self, $from, $channel) = (shift, shift, shift);
   my @nicks = @_;
   &_multimodes($from, $channel, '-o', @nicks);
}

sub halfop {
   my ($self, $from, $channel) = (shift, shift, shift);
   my @nicks = @_;
   &_multimodes($from, $channel, '+h', @nicks);
}
 
sub dehalfop {
   my ($self, $from, $channel) = (shift, shift, shift);
   my @nicks = @_;  
   &_multimodes($from, $channel, '-h', @nicks);
}

sub voice {
   my ($self, $from, $channel) = (shift, shift, shift);
   my @nicks = @_;
   &_multimodes($from, $channel, '+v', @nicks);
}

sub devoice {
   my ($self, $from, $channel) = (shift, shift, shift);
   my @nicks = @_;
   &_multimodes($from, $channel, '-v', @nicks);
}
	 
								  

1;
