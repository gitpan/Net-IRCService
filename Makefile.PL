use ExtUtils::MakeMaker;

#
# Found in a norwegian book about Internet Relay Chat (Internet Relay Chat - IRC by Lars M. Kvanum,
# ISBN 0-13-271164-8, Prentice Hall):
#
# RTFM means: Here, "Sir; Let Me Do This For You, Sir (Military)"
#

# So, You want a Makefile?! RTFM!


WriteMakefile(
	'NAME'		=> 'Net::IRCService',
	'PM'		=> {
		'IRCService.pm'	=> '$(INST_LIBDIR)/IRCService.pm',
		'Hybrid6.pm'	=> '$(INST_LIBDIR)/IRCService/Hybrid6.pm',
		'Hybrid7.pm'	=> '$(INST_LIBDIR)/IRCService/Hybrid7.pm',
		'Bahamut3.pm'	=> '$(INST_LIBDIR)/IRCService/Bahamut3.pm',
		'DB.pm'	        => '$(INST_LIBDIR)/IRCService/DB.pm'
			},
	'VERSION_FROM'	=> 'IRCService.pm',
	'PREREQ_PM'		=> {

		'POSIX' 	=> 0,
		'IO::Select'	=> 0,
		'IO::Socket'	=> 0,
		'Socket'	=> 0,
		'Fcntl'		=> 0
			},
	'dist' => { 'COMPRESS' => 'gzip --best' },
	($] >= 5.005 ? (
		ABSTRACT_FROM => 'IRCService.pm',
		AUTHOR     => 'K. S. Berulfsen <kaysb@uten.net>') : ()),
);
