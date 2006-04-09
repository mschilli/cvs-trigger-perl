######################################################################
# Test suite for Cvs::Trigger
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
use Log::Log4perl qw(:easy);
use Cvs::Trigger;
use Sysadm::Install qw(:all);
use YAML qw(LoadFile);

BEGIN { use_ok('Cvs::Trigger') };

#Log::Log4perl->easy_init($DEBUG);

my $c = Cvs::Temp->new();
$c->module_import();

my $code = $c->test_trigger_code("commitinfo", 1);
my $script = "$c->{bin_dir}/trigger";
blurt $code, $script;
chmod 0755, $script;

my $vcode = $c->test_trigger_code("verifymsg", 1);
my $vscript = "$c->{bin_dir}/vtrigger";
blurt $vcode, $vscript;
chmod 0755, $vscript;

my $commitinfo = "$c->{cvsroot}/CVSROOT/commitinfo";
chmod 0644, $commitinfo or die "cannot chmod $commitinfo";
blurt "DEFAULT $script", $commitinfo;

my $verifymsg = "$c->{cvsroot}/CVSROOT/verifymsg";
chmod 0644, $verifymsg or die "cannot chmod $verifymsg";
blurt "DEFAULT $vscript", $verifymsg;

    # Single file
$c->files_commit("m/a/a1.txt");
my $yml = LoadFile("$c->{out_dir}/trigger.yml.1");
is($yml->{files}->[0], "a1.txt", "yml trigger check for single file");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");

$yml = LoadFile("$c->{out_dir}/trigger.yml.2");
is($yml->{message}, "m/a/a1.txt-check-in-message\n", 
                    "verifymsg message");
is($yml->{cache}->{"$c->{cvsroot}/m/a"}->[0], "a1.txt", 
                   "cached filename");

    # Multiple files, same dir
$c->files_commit("m/a/a1.txt", "m/a/a2.txt");
$yml = LoadFile("$c->{out_dir}/trigger.yml.3");
is($yml->{files}->[0], "a1.txt", "yml trigger check for mult files (same dir)");
is($yml->{files}->[1], "a2.txt", "yml trigger check for mult files (same dir)");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");

$yml = LoadFile("$c->{out_dir}/trigger.yml.4");
is($yml->{message}, "m/a/a1.txt m/a/a2.txt-check-in-message\n", 
                    "verifymsg message");

is($yml->{cache}->{"$c->{cvsroot}/m/a"}->[0], "a1.txt", 
                   "cached filename");
is($yml->{cache}->{"$c->{cvsroot}/m/a"}->[1], "a2.txt", 
                   "cached filename");

#<STDIN>;