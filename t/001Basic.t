######################################################################
# Test suite for Cvs::Trigger
# by Mike Schilli <mschilli@yahoo-inc.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
BEGIN { use_ok('Cvs::Trigger') };

ok(1);
like("123", qr/^\d+$/);
