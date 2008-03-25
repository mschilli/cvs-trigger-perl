######################################################################
# Test suite for Cvs::Trigger
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More tests => 29;
use Log::Log4perl qw(:easy);
use Cvs::Trigger;
use Sysadm::Install qw(:all);
use YAML qw(LoadFile);

BEGIN { use_ok('Cvs::Trigger') };

#Log::Log4perl->easy_init($DEBUG);

my $c = Cvs::Temp->new();
$c->init();
$c->module_import();

my $code = $c->test_trigger_code("loginfo", 0);
my $script = "$c->{bin_dir}/ltrigger";
blurt $code, $script;
chmod 0755, $script;

my $loginfo = "$c->{local_root}/CVSROOT/loginfo";
chmod 0644, $loginfo or die "cannot chmod $loginfo";
blurt "DEFAULT $script", $loginfo;

$c->admin_rebuild();

    # Single file
$c->files_commit("m/a/a1.txt");
my $yml = LoadFile("$c->{out_dir}/trigger.yml.2");
is($yml->{files}->[0], "a1.txt", "yml trigger check for single file");
is(scalar @{ $yml->{files} }, 1, "1 file changed");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");
is($yml->{message}, "m/a/a1.txt-check-in-message\n", 
   "yml trigger check message");

    # Multiple files, same dir
$c->files_commit("m/a/a1.txt", "m/a/a2.txt");
$yml = LoadFile("$c->{out_dir}/trigger.yml.3");
is($yml->{files}->[0], "a1.txt", "yml trigger check for mult files (same dir)");
is($yml->{files}->[1], "a2.txt", "yml trigger check for mult files (same dir)");
is(scalar @{ $yml->{files} }, 2, "2 files changed");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");

    # Loginfo with file/revision information
$code = $c->test_trigger_code("loginfo", 0, "{rev_fmt => 'sVv'}");
$script = "$c->{bin_dir}/ltrigger";
blurt $code, $script;
chmod 0755, $script;

my $line = $c->loginfo_line($script);

blurt "$line\n", $loginfo;
$c->admin_rebuild();

    # Single file
$c->files_commit("m/a/a1.txt");
#use Data::Dumper;
#print Dumper($c);
#<>;

$yml = LoadFile("$c->{out_dir}/trigger.yml.5");

is($yml->{revs}->{"a1.txt"}->[0], "1.3", "revision check single file");
is($yml->{revs}->{"a1.txt"}->[1], "1.4", "revision check single file");

    # Multiple files, same dir
$c->files_commit("m/a/a1.txt", "m/a/a2.txt");
$yml = LoadFile("$c->{out_dir}/trigger.yml.6");
is($yml->{files}->[0], "a1.txt", "yml trigger check for mult files (same dir)");
is($yml->{files}->[1], "a2.txt", "yml trigger check for mult files (same dir)");
is(scalar @{ $yml->{files} }, 2, "2 files changed");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");

is($yml->{revs}->{"a1.txt"}->[0], "1.4", "revision check two files same dir");
is($yml->{revs}->{"a1.txt"}->[1], "1.5", "revision check two files same dir");
is($yml->{revs}->{"a2.txt"}->[0], "1.2", "revision check two files same dir");
is($yml->{revs}->{"a2.txt"}->[1], "1.3", "revision check two files same dir");

    # More files in different dirs
$c->files_commit("m/a/a1.txt", "m/a/b/b.txt");
$yml = LoadFile("$c->{out_dir}/trigger.yml.7");

is($yml->{files}->[0], "a1.txt", 
                       "yml trigger check for two files (different dirs)");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");

is($yml->{revs}->{"a1.txt"}->[0], "1.5", "revision check two files diff dir");
is($yml->{revs}->{"a1.txt"}->[1], "1.6", "revision check two files diff dir");
is(scalar keys %{$yml->{revs}}, 1, "revision check two files diff dir");

$yml = LoadFile("$c->{out_dir}/trigger.yml.8");
is($yml->{files}->[0], "b.txt", 
                       "yml trigger check for two files (different dirs)");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a/b", "yml trigger check repo_dir");

is($yml->{revs}->{"b.txt"}->[0], "1.1.1.1", 
                  "revision check two files diff dir");
is($yml->{revs}->{"b.txt"}->[1], "1.2", 
                  "revision check two files diff dir");
is(scalar keys %{$yml->{revs}}, 1, "revision check two files diff dir");

#<STDIN>;
