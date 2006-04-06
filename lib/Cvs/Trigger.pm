###########################################
package Cvs::Trigger;
###########################################
use strict;
use warnings;
use File::Spec;

our $VERSION = "0.01";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        %options,
    };

    bless $self, $class;
}

###########################################
sub find_bin {
###########################################
    my($path, $prog) = @_;

    return undef unless defined $ENV{PATH};

    for my $path (split /:/, $ENV{PATH}) {
        my $try = File::Spec->catfile($path, $prog);
        if(-x $try) {
            return $try;
        } 
    }

    return undef;
}

###########################################
package Cvs::Temp;
###########################################
use strict;
use warnings;
use File::Temp qw(tempdir);
use Sysadm::Install qw(:all);
use Log::Log4perl qw(:easy);

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        tmp_dir => tempdir(CLEANUP => 1),
        %options,
    };

    $self->{cvs_bin} = bin_find("cvs") unless defined $self->{cvs_bin};

    my($stdout, $stderr, $rc) = tap $self->{cvs_bin}, "-d", 
                                    $self->{tmp_dir}, "init";

    if($rc) {
        LOGDIE "Cannot create cvs repo in $self->{tmp_dir} ($stderr)";
    }

    bless $self, $class;
}

###########################################
sub tmp_dir {
###########################################
    my($self, $newdir) = @_;

    $self->{tmp_dir} = $newdir if defined $newdir;
    return $self->{tmp_dir};
}

1;

__END__

=head1 NAME

Cvs::Trigger - blah blah blah

=head1 SYNOPSIS

    use Cvs::Trigger;

=head1 DESCRIPTION

Cvs::Trigger blah blah blah.

=head1 EXAMPLES

  $ perl -MCvs::Trigger -le 'print $foo'

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <mschilli@yahoo-inc.com>
