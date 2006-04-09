######################################################################
# Makefile.PL for Cvs::Trigger
# 2005, Mike Schilli <m@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Cvs::Trigger',
    'VERSION_FROM' => 'lib/Cvs/Trigger.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Sysadm::Install  => 0,
        YAML             => 0,
        Cache::FileCache => 0,
        Storable         => 0,
        POSIX            => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Cvs/Trigger.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
);
