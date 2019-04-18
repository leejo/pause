#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

open( my $fh,'<','cpanfile' )
    || die "Couldn't open cpanfile to get deps: $!";

my @deps = map { ( split( /'/,$_ ) )[1]; } <$fh>;
close( $fh );

WriteMakefile(
              NAME          => 'PAUSE',
              VERSION_FROM  => 'lib/PAUSE.pm',
              ABSTRACT_FROM => 'lib/PAUSE.pod',
              AUTHOR        => 'Andreas Koenig <andreas.koenig.7os6VVqR@franz.ak.mind.de>',
              LICENSE       => 'perl',
              PREREQ_PM     => { map +($_ => 0), @deps },
              SIGN => 1,
              test => { RECURSIVE_TEST_FILES => 1 },
              ($ExtUtils::MakeMaker::VERSION >= 6.4502 ?
               (META_ADD => {
                             resources => {
                                 repository => "git://github.com/andk/pause.git",
                             },
                             keywords => ['CPAN','perl','perl authors upload server'],
                            }) : ()),
             );

sub MY::postamble {
  <<EOF;
cpanshell ::
\t\$(PERL) -MCPAN -e shell

rsynctest ::
\t\$(ECHO) USER=\$(USER) RSYNC_PASSWORD=\$(RSYNC_PASSWORD) ...
\tUSER=\$(USER) RSYNC_PASSWORD=\$(RSYNC_PASSWORD) rsync --port=8732 pause.perl.org::PAUSE/authors/02STAMP

getdump:
	rsync -P pause.perl.org::pausedata/moddump.current .
	\@echo You need to call next: make recorddump

recorddump: moddump.current
	mysql -u root -p mod < moddump.current

stopslave:
	mysql -u root -p -e 'stop slave'

startslave:
	mysql -u root -p -e 'start slave; show slave status\\G'

doc/mod.schema.txt:
	mysqldump -u root -p mod          --quote-names=false --no-data --skip-add-drop-table > \$\@

doc/authen_pause.schema.txt:
	mysqldump -u root -p authen_pause --quote-names=false --no-data --skip-add-drop-table > \$\@

htdocs/namingmodules.html: htdocs/namingmodules.pod
	-[ -r \$\@ ] && chmod +w \$\@
	-\$(PERL) -MPod::Xhtml -e 'Pod::Xhtml->new->parse_from_file(\*ARGV)' htdocs/namingmodules.pod > \$\@

EOF
}
