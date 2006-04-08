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
        cvsroot    => tempdir(CLEANUP => 1),
        local_root => tempdir(CLEANUP => 1),
        %options,
    };

    $self->{cvs_bin}  = bin_find("cvs") unless defined $self->{cvs_bin};
    $self->{perl_bin} = bin_find("perl") unless 
                        defined $self->{perl_bin};

    my($stdout, $stderr, $rc) = tap $self->{cvs_bin}, "-d", 
                                    $self->{cvsroot}, "init";

    if($rc) {
        LOGDIE "Cannot create cvs repo in $self->{cvsroot} ($stderr)";
    }

    DEBUG "New cvs created in $self->{cvsroot}";

    bless $self, $class;
}

###########################################
sub test_trigger_code {
###########################################
    my($self, $tmpfile, $shebang) = @_;

    $shebang ||= "#!" . $self->{perl_bin};

    my $script = <<'EOT';
_shebang_
use Sysadm::Install qw(:all);
use YAML qw(DumpFile);
use Data::Dumper;
my $in = join '', <STDIN>;
unshift @ARGV, $in;
push @ARGV, slurp($ARGV[0]) if $ARGV[0] && -f  $ARGV[0];
blurt(Dumper(\@ARGV), "_tmpfile_", 1);
die "Whoa************************************************************************************Whoaa!";
EOT

    $script =~ s/_shebang_/$shebang/g;
    $script =~ s/_tmpfile_/$tmpfile/g;

    return $script;
}

###########################################
sub module_import {
###########################################
    my($self) = @_;

    my($dir) = tempdir(CLEANUP => 1); 

    DEBUG "Temporary workspace dir $dir";

    cd $dir;
    mkd "foo/bar";
    blurt "footext", "foo/foo.txt";
    blurt "bartext", "foo/bar/bar.txt";
    $self->cvs_cmd("import", "-m", "msg", "foo", "tag1", "tag2");
    cdback;

    cd $self->{local_root};
    $self->cvs_cmd("co", "foo");
    cdback;
}

###########################################
sub file_check_in {
###########################################
    my($self) = @_;

    my $dir = $self->{local_root};

    cd "$dir/foo";

    blurt rand(1E10), "foo/foo.txt";
    blurt rand(1E10), "foo/bar/bar.txt";

    $self->cvs_cmd("commit", "-m", "foo-check-in-message");

    cdback;
}

###########################################
sub cvs_cmd {
###########################################
    my($self, @cmd) = @_;

    unshift @cmd, $self->{cvs_bin}, "-d", $self->{cvsroot};
    DEBUG "Running CVS command @cmd";

    my($stdout, $stderr, $rc) = tap @cmd;

    if($rc) {
        LOGDIE "@cmd failed: $stderr";
    }

    DEBUG "@cmd succeeded: $stdout";
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
