# Tests for PerlIO::via::gzip

use 5.012000;
use warnings;

use Test::More;
use File::Copy;

use_ok ("PerlIO::via::gzip");

my $tgz = "test.gz";	END { unlink $tgz }

my %txt;
my %gz;
for my $type (qw( plain banner )) {
    local $/;
    open my $fh, "<", "files/$type.txt"  or die "$type.txt: $!\n";
    $txt{$type} = <$fh>;
    close $fh;

    open    $fh, "<", "sandbox/$type.gz" or die "$type.gz:  $!\n";
    $gz{$type}  = <$fh>;
    close $fh;
    }

# Check defaults
#cmp_ok(PerlIO::via::gz->level, "==", 1, "default worklevel");

my $fh;

# Opening/closing
ok ( open  ($fh, "<:via(gzip)",  "sandbox/plain.gz"),	"open for reading");
ok ( close ($fh),					"close file");

ok ( open  ($fh, "+<:via(gzip)", "sandbox/plain.gz"),	"read+write is impossible");

ok ( open  ($fh, ">:via(gzip)",  $tgz),			"open for write");
ok ( close ($fh),					"close file");

ok ( open  ($fh, "+>:via(gzip)", $tgz),			"write+read is impossible");
ok ( open  ($fh, ">>:via(gzip)", $tgz),			"append is not supported");

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

	ok (open (my $fz, "<:via(gzip)", "sandbox/$type.gz"), "Open $type");
	my $data = <$fz>;
	is ($data, $txt{$type}, "$type decompression");
	}

    # Compression
    for my $type (qw( plain banner )) {
	my $fh;
	ok (open ($fh, ">:via(gzip)", $tgz), "Open $type compress");

	ok ((print { $fh } $txt{$type}), "Write");
	ok (close ($fh), "Close");
	}

    # Roundtrip
    for my $type (qw( plain banner )) {
	my $fh;
	ok (open ($fh, ">:via(gzip)", $tgz), "Open $type compress");

	ok ((print { $fh } $txt{$type}), "Write");
	ok (close ($fh), "Close");

	ok (open ($fh, "<:via(gzip)", $tgz), "Open $type uncompress");
	my $data = <$fh>;
	is ($data, $txt{$type}, "$type compare");
	}
    }

done_testing;
