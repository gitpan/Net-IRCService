# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use Net::IRCService;
ok(1); # If we made it this far, we're ok.
use Net::IRCService::DB;
ok(2);
my $db = Net::IRCService::DB->new();
ok(3);
#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

