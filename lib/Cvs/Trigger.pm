###########################################
package Cvs::Trigger;
###########################################
use strict;
use warnings;
use File::Spec;
use Log::Log4perl qw(:easy);
use Data::Dumper;

Log::Log4perl->easy_init($DEBUG);

our $VERSION = "0.01";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        routines => { 'commitinfo' => \&commitinfo,
                      'loginfo'    => \&loginfo,
                      'verifymsg'  => \&verifymsg,
                    },
        %options,
    };

    bless $self, $class;
}

###########################################
sub parse {
###########################################
    my($self, $type) = @_;

    $type = $self->{type} unless defined $type;
    LOGDIE "No type defined" unless defined $type;

    if(exists $self->{routines}->{$type}) {
        $self->{routines}->{$type}->($self);
    } else {
        LOGDIE "Unknown type: $type";
    }
}

###########################################
sub commitinfo {
###########################################
    my($self) = @_;

    if(@ARGV < 2) {
        LOGDIE "Argument error: commitinfo expects at least 2 parameters";
    }

    my($repo_dir, $file) = @ARGV[-2, -1];

    my @opts = ();
    @opts = @ARGV[2 .. $#ARGV-2] if @ARGV > 2;

    my $res = {
        repo_dir => $repo_dir,
        file     => $file,
        opts     => \@opts,
        trigger  => "commitinfo",
        argv     => \@ARGV,
    };

    DEBUG "commitinfo parameters: ", Dumper($res);

    return $res;
}

###########################################
sub verifymsg {
###########################################
    my($self) = @_;

    if(@ARGV < 1) {
        LOGDIE "Argument error: commitinfo expects at least 2 parameters";
    }

    my($tmp_file) = @ARGV;

    my $data = _slurp($tmp_file);

    my $res = {
        opts    => \@ARGV[1,],
        message => $data,
    };

    DEBUG "verifymsg parameters: ", Dumper($res);
}

#2006/04/08 13:29:22 argv=verifymsg /tmp/cvsDYgcCY
#2006/04/08 13:29:22 Slurping data from /tmp/cvsDYgcCY
#2006/04/08 13:29:22 Read (7)[foobar.] from /tmp/cvsDYgcCY
#2006/04/08 13:29:22 data=foobar
#2006/04/08 13:29:22 Slurping data from /tmp/cvsDYgcCY
#2006/04/08 13:29:22 Read (7)[foobar.] from /tmp/cvsDYgcCY
#2006/04/08 13:29:22 msg=foobar
#2006/04/08 13:29:22 pid=20651 ppid=20644

###########################################
sub loginfo {
###########################################
    my($self) = @_;

    my $data = <STDIN>;

    my $res = {
        opts    => \@ARGV,
        message => $data,
    };

}

#2006/04/08 13:29:22 argv=loginfo
#2006/04/08 13:29:22 pid=20656 ppid=20653
#2006/04/08 13:29:22 stdin: a txt,1.20,1.21
#2006/04/08 13:29:22 stdin: Update of /home/mschilli/testcvs/a
#2006/04/08 13:29:22 stdin: In directory mybox:/mnt/big2/mschilli.do.not.delete/tmp/a
#2006/04/08 13:29:22 stdin: 
#2006/04/08 13:29:22 stdin: Modified Files:
#2006/04/08 13:29:22 stdin:      txt 
#2006/04/08 13:29:22 stdin: Log Message:
#2006/04/08 13:29:22 stdin: foobar
#2006/04/08 13:29:22 stdin: 

###########################################
sub _slurp {
###########################################
    my($file) = @_;

    local $/ = undef;

    open FILE, "<$file" or
        LOGDIE "Cannot open $file ($!)";
    my $data = <FILE>;
    close FILE;

    return $data;
}

#2006/04/08 13:29:11 argv=commitinfo /home/mschilli/testcvs/a txt
#2006/04/08 13:29:11 Slurping data from /home/mschilli/testcvs/a
#2006/04/08 13:29:11 Read (0)[] from /home/mschilli/testcvs/a
#2006/04/08 13:29:11 data=
#2006/04/08 13:29:11 pid=20645 ppid=20644
#

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
my $in = "no-in"; #join '', <STDIN>;
unshift @ARGV, $in;
push @ARGV, slurp($ARGV[0]) if $ARGV[0] && -f  $ARGV[0];
blurt(Dumper(\@ARGV), "_tmpfile_", 1);
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
