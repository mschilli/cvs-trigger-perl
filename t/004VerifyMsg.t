######################################################################
# Test suite for Cvs::Trigger
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More tests => 2;
use Log::Log4perl qw(:easy);
use Cvs::Trigger;
use Sysadm::Install qw(:all);
use YAML qw(LoadFile);

BEGIN { use_ok('Cvs::Trigger') };

#Log::Log4perl->easy_init($DEBUG);

my $c = Cvs::Temp->new();
$c->init();
$c->module_import();

my $vcode = $c->test_trigger_code("verifymsg", 1);
my $vscript = "$c->{bin_dir}/vtrigger";
blurt $vcode, $vscript;
chmod 0755, $vscript;

my $verifymsg = "$c->{local_root}/CVSROOT/verifymsg";
chmod 0644, $verifymsg or die "cannot chmod $verifymsg";
blurt "DEFAULT $vscript", $verifymsg;

$c->admin_rebuild();

    # Check-in message containing a quote
$c->single_file_commit("file_content\n", "m/a/a1.txt", 
                       "message with a ' quote");

my $yml = LoadFile("$c->{out_dir}/trigger.yml.1");
is($yml->{message}, "message with a ' quote\n", 
   "message with a single quote");
