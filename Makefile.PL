######################################################################
# Makefile.PL for Cvs::Trigger
# 2005, Mike Schilli <m@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/cvs-trigger-perl.git',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Cvs::Trigger',
    'VERSION_FROM' => 'lib/Cvs/Trigger.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Sysadm::Install  => 0.26, # needs the tapquote fix
        YAML             => 0.66,
        Cache::FileCache => 0,
        Storable         => 0,
        POSIX            => 0,
        File::Temp       => 0.20,
        File::Path       => 2.04,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Cvs/Trigger.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
);
