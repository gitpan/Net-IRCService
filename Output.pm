package Net::IRCService::Output;

#
# Net::IRCService
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

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

	send_motd
	send_no_motd
	send_version
	send_admin
	send_no_admin
	send_whois
);
our $VERSION = '0.02';


# Preloaded methods go here.

BEGIN {

}

sub irc_send { &Net::IRCService::irc_send(@_); }

sub send_motd { ## send_motd (nick, array_with_motd)

	my $server_name=$Net::IRCService::server_name;
	my $nick = shift;
	my @motd = @_;
	&irc_send(":$server_name 375 $nick :- $server_name Message of the day - ");
	&irc_send(":$server_name 372 $nick :- $_") foreach (@motd);
	&irc_send(":$server_name 376 $nick :- End of /MOTD command");

}

sub send_no_motd {
	my $server_name=$Net::IRCService::server_name;
	my $nick=shift;
	&irc_send(":$server_name 422 $nick :MOTD File is missing");
}

sub send_version {
	my $server_name=$Net::IRCService::server_name;
	my $nick=shift;
	my $version=shift;
	my $comment=shift;
	&irc_send(":$server_name 351 $version $server_name :$comment");
}

sub send_admin {
	my $server_name=$Net::IRCService::server_name;
	my $nick=shift;
	my $ai1=shift;
	my $ai2=shift;
	my $email=shift;
	&irc_send(":$server_name 256 $nick $server_name :Administrative info");
	&irc_send(":$server_name 257 $nick :$ai1");
	&irc_send(":$server_name 258 $nick :$ai2");
	&irc_send(":$server_name 259 $nick :$email");
}

sub send_no_admin {
	my $server_name=$Net::IRCService::server_name;
	my $nick=shift;
	&irc_send(":$server_name 423 $nick $server_name :No administrative info available");
}

sub send_whois {
	my $server_name=$Net::IRCService::server_name;
	my $server_comment=$Net::IRCService::server_comment;
	my $target=shift;
	my ($nick,$ident,$host,$realname,$channels,$oper,$away, $idle, $signon)=@_;

	&irc_send(":$server_name 311 $target $nick $ident $host * :$realname");
	&irc_send(":$server_name 319 $target $nick :$channels");
	&irc_send(":$server_name 312 $target $nick $server_name :$server_comment");
	&irc_send(":$server_name 301 $target $nick :$away") if ($away ne '');
	&irc_send(":$server_name 313 $target $nick :is an IRC Operator") if ($oper ne '');
	&irc_send(":$server_name 317 $target $nick $idle $signon :seconds idle, signon time");
	&irc_send(":$server_name 318 $target $nick :End of /WHOIS list.");
}
	
	



1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::IRC-Service - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Net::IRC-Service;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Net::IRC-Service, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 SEE ALSO

L<perl>.

=cut
