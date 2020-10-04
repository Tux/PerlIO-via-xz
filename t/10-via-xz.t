# Tests for PerlIO::via::xz

use 5.12.0;
use warnings;

use Test::More;

use File::Copy;

use_ok ("PerlIO::via::xz");

my $txz = "test.xz";	END { unlink $txz }

my %txt;
my %xz;
for my $type (qw( plain banner )) {
    local $/;
    open my $fh, "<", "files/$type.txt" or die "$type.txt: $!\n";
    $txt{$type} = <$fh>;
    close $fh;

    open    $fh, "<", "files/$type.xz"  or die "$type.xz:  $!\n";
    $xz{$type}  = <$fh>;
    close $fh;
    }

# Check defaults
#cmp_ok(PerlIO::via::xz->level, "==", 1, "default worklevel");

my $fh;

# Opening/closing
ok ( open  ($fh, "<:via(xz)",  "files/plain.xz"),	"open for reading");
ok ( close ($fh),					"close file");

ok (!open  ($fh, "+<:via(xz)", "files/plain.xz"),	"read+write is impossible");

ok ( open  ($fh, ">:via(xz)",  $txz),			"open for write");
ok ( close ($fh),					"close file");

ok (!open  ($fh, "+>:via(xz)", $txz),			"write+read is impossible");
ok (!open  ($fh, ">>:via(xz)", $txz),			"append is not supported");

for ([ MORMAL => "\xff\xfe\xff\xfe" x 16	],
     [ EMPTY  => ""				],
     [ UNDEF  => undef				],
     [ REF    => \40				],) {

    my ($rst, $rs) = @$_;
    local $/ = $rs;
    $rst eq "REF" and $txt{$_} = substr $txt{$_}, 0, 40 for qw( plain banner );

    ok (1, "Testing for RS $rst");

    # Decompression
    for my $type (qw( plain banner )) {

	ok (open (my $fz, "<:via(xz)", "files/$type.xz"), "Open $type");
	my $data = <$fz>;
	if (defined $rs) {
	    is ($data, $txt{$type}, "$type decompression");
	    }
	else { TODO:{ local $TODO = "local \$/ fails on decompress";
	    # Shorten the error message
	    is (substr ($data, 0, 40), substr ($txt{$type}, 0, 40),
		"$type decompression");
	    }}
	}

    # Compression
    for my $type (qw( plain banner )) {
	my $fh;
	ok (open ($fh, ">:via(xz)", $txz), "Open $type compress");

	ok ((print { $fh } $txt{$type}), "Write");
	ok (close ($fh), "Close");
	}

    # Roundtrip
    for my $type (qw( plain banner )) {
	my $fh;
	ok (open ($fh, ">:via(xz)", $txz), "Open $type compress");

	ok ((print { $fh } $txt{$type}), "Write");
	ok (close ($fh), "Close");

	ok (open ($fh, "<:via(xz)", $txz), "Open $type uncompress");
	my $data = <$fh>;
	if (defined $rs) {
	    is ($data, $txt{$type}, "$type compare");
	    }
	else { TODO:{ local $TODO = "local \$/ fails on decompress";
	    # Shorten the error message
	    is (substr ($data, 0, 40), substr ($txt{$type}, 0, 40),
		"$type compare");
	    }}
	}
    }

done_testing;
