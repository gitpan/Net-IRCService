use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Net::IRCService',
	'PM'		=> {
		'IRCService.pm'	=> '$(INST_LIBDIR)/IRCService.pm',
		'Hybrid6.pm'	=> '$(INST_LIBDIR)/IRCService/Hybrid6.pm',
		'Hybrid7.pm'	=> '$(INST_LIBDIR)/IRCService/Hybrid7.pm',
		'Bahamut3.pm'	=> '$(INST_LIBDIR)/IRCService/Bahamut3.pm'
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
