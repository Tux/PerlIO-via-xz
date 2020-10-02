#!/pro/bin/perl

use strict;
use warnings;

use Test::More 0.93;
eval "use Test::MinimumVersion";
if ($@) {
    print "1..0 # Test::MinimumVersion required for compatability tests\n";
    exit 0;
    }

all_minimum_version_ok ("5.012000", { paths =>
    [qw( Makefile.PL lib t xt examples )]});

done_testing ();
