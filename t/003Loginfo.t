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

Log::Log4perl->easy_init($DEBUG);

my $c = Cvs::Temp->new();
$c->module_import();

my $code = $c->test_trigger_code("loginfo", 0);
my $script = "$c->{bin_dir}/ltrigger";
blurt $code, $script;
chmod 0755, $script;

my $loginfo = "$c->{cvsroot}/CVSROOT/loginfo";
chmod 0644, $loginfo or die "cannot chmod $loginfo";
blurt "DEFAULT $script", $loginfo;

    # Single file
$c->files_commit("m/a/a1.txt");
my $yml = LoadFile("$c->{out_dir}/trigger.yml.1");
is($yml->{files}->[0], "a1.txt", "yml trigger check for single file");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");
is($yml->{message}, "m/a/a1.txt-check-in-message\n", 
   "yml trigger check message");
is($yml->{local_dir}, "$c->{local_root}/m/a", "local dir");

    # Multiple files, same dir
$c->files_commit("m/a/a1.txt", "m/a/a2.txt");
$yml = LoadFile("$c->{out_dir}/trigger.yml.2");
is($yml->{files}->[0], "a1.txt", "yml trigger check for mult files (same dir)");
is($yml->{files}->[1], "a2.txt", "yml trigger check for mult files (same dir)");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");
