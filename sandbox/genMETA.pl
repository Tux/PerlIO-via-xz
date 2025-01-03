#!/pro/bin/perl

use strict;
use warnings;

use Getopt::Long qw(:config bundling nopermute);
my $check = 0;
my $opt_v = 0;
GetOptions (
    "c|check"		=> \$check,
    "v|verbose:1"	=> \$opt_v,
    ) or die "usage: $0 [--check]\n";

use lib "sandbox";
use genMETA;
my $meta = genMETA->new (
    from    => "lib/PerlIO/via/xz.pm",
    verbose => $opt_v,
    );

$meta->from_data (<DATA>);
$meta->gen_cpanfile ();

if ($check) {
    $meta->check_encoding ();
    $meta->check_required ();
    $meta->check_minimum  ("5.12", [ "Makefile.PL", "lib", "t" ]);
    $meta->done_testing   ();
    }
elsif ($opt_v) {
    $meta->print_yaml ();
    }
else {
    $meta->fix_meta ();
    }

__END__
--- #YAML:1.0
name:                     PerlIO-via-xz
version:                  VERSION
abstract:                 PerlIO layer for XZ (de)compression
license:                  perl
author:
    - H.Merijn Brand <hmbrand@cpan.org>
generated_by:             Author
distribution_type:        module
provides:
    PerlIO::via::xz:
        file:             lib/PerlIO/via/xz.pm
        version:          VERSION
requires:
    perl:                 5.012000
    Carp:                 0
    PerlIO:               0
    IO::Compress::Xz:     2.100
    IO::Uncompress::UnXz: 2.100
configure_requires:
    ExtUtils::MakeMaker:  0
configure_recommends:
    ExtUtils::MakeMaker:  7.22
configure_suggests:
    ExtUtils::MakeMaker:  7.70
test_requires:
    Test::More:           0
recommends:
    IO::Compress::Xz:     2.213
    IO::Uncompress::UnXz: 2.213
test_recommends:
    Test::More:           1.302207
resources:
    license:              http://dev.perl.org/licenses/
    homepage:             https://metacpan.org/pod/PerlIO::via::xz
    repository:           https://github.com/Tux/PerlIO-via-xz
    bugtracker:           https://github.com/Tux/PerlIO-via-xz/issues
    IRC:                  irc://irc.perl.org/#csv
meta-spec:
    version:              1.4
    url:                  http://module-build.sourceforge.net/META-spec-v1.4.html
