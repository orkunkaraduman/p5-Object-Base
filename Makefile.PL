use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
	NAME				=> 'Object::Base',
	VERSION				=> '1.07',
	MIN_PERL_VERSION	=> '5.008',
	PREREQ_PM			=> {
		'threads'		=> '1.72',
		'threads::shared' => '1.28',
		'forks'		=> '0.29',
	},
	EXE_FILES			=> [qw(
	)],
	AUTHOR				=> 'Orkun Karaduman <orkunkaraduman@gmail.com>',
	ABSTRACT			=> 'Multi-threaded base class to establish a class deriving relationship with parent classes',
	LICENSE				=> 'gpl_3',
	META_MERGE			=> {
		'meta-spec'		=> {
			version		=> 2,
		},
		resources => {
			homepage	=> 'https://metacpan.org/release/Object-Base',
			license		=> 'https://www.gnu.org/licenses/gpl-3.0.html',
			repository	=> {
				type	=> 'git',
				url		=> 'git://git@github.com:orkunkaraduman/p5-Object-Base.git',
				web		=> 'https://github.com/orkunkaraduman/p5-Object-Base',
			},
			bugtracker	=> {
				web		=> 'https://github.com/orkunkaraduman/p5-Object-Base/issues',
				mailto	=> 'bug-Object-Base@rt.cpan.org',
			},
		},
	},
);
