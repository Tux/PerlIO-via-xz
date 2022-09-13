#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Links";
plan skip_all => "Test::Pod::Links required for testing POD links" if $@;
Test::Pod::Links->new->pod_file_ok ("lib/PerlIO/via/xz.pm");
done_testing;
