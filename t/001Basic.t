######################################################################
# Test suite for Cvs::Trigger
# by Mike Schilli <mschilli@yahoo-inc.com>
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

my $code = $c->test_trigger_code("commitinfo");
my $script = "$c->{bin_dir}/trigger";
blurt $code, $script;
chmod 0755, $script;

my $commitinfo = "$c->{cvsroot}/CVSROOT/commitinfo";
chmod 0644, $commitinfo or die "cannot chmod $commitinfo";
blurt "DEFAULT $script", $commitinfo;

$c->files_commit("m/a/a1.txt");
my $yml = LoadFile("$c->{out_dir}/trigger.yml");
is($yml->{files}->[0], "a1.txt", "yml trigger check for single file");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");
<STDIN>;
