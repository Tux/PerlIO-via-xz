#!/pro/bin/perl

use 5.012000;
use warnings;

use Test::More;

BEGIN { use_ok ("PerlIO::via::gzip"); }
use_ok ("File::Temp");
use_ok ("IO::Compress::Gzip");
use_ok ("IO::Uncompress::Gunzip");

use File::Temp             qw( tempfile );
use IO::Compress::Gzip     qw( gzip     );
use IO::Uncompress::Gunzip qw( gunzip   );

my ($tmph, $tmpf) = tempfile;
ok (open ($tmph, ">:via(gzip)", $tmpf), "open tempfile for compressed writing");
my ($first,$last) = (rand, rand);
say $tmph $first;
say $tmph rand for 0 .. 1000;
say $tmph $last;
ok ($tmph->close, "flush and put the lid down");

my $data;
gunzip ($tmpf => \$data);
is ((split m{$/}, $data)[ 0], $first, "first entry roundtrip");
is ((split m{$/}, $data)[-1], $last,  "last entry roundtrip");
my $works = "It works!";
gzip (\$works => $tmpf);
undef $tmph;
ok (open ($tmph, "<:via(gzip)", $tmpf), "open tempfile for decompressed reading");
is ($data = <$tmph>, $works, "reading roundtrip" );

done_testing;
