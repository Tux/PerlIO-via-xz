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

foreach my $rs ("\xff\xfe\xff\xfe" x 16, undef) {
    local $/ = $rs;
    # Decompression
    for my $type (qw( plain banner )) {

	ok (open (my $fz, "<:via(xz)", "files/$type.xz"), "Open $type");
	is (scalar <$fz>, $txt{$type}, "$type decompression");
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
	is (scalar <$fh>, $txt{$type}, "Compare");
	}
    }

done_testing;
