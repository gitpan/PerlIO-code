use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PerlIO::code',
    AUTHOR              => 'Goro Fuji',
    VERSION_FROM        => 'lib/PerlIO/code.pm',
    ABSTRACT_FROM       => 'lib/PerlIO/code.pm',

    LICENSE             => 'perl',

    clean               => { FILES => 'PerlIO-code-*' },
);
