#!/pro/bin/perl

use 5.12.0;
use warnings;

use Test::More;
use IO::Compress::Gzip     qw( $GzipError   );
use IO::Uncompress::Gunzip qw( $GunzipError );

ok (my $txt = "Lorem ipsum dolor sit amet\n", "Set text");
my $gz;

for ([ MORMAL => "\xff\xfe\xff\xfe" x 16	],
     [ EMPTY  => ""				],
     [ UNDEF  => undef				],
     [ REF    => \40				],) {

    my ($rst, $rs) = @$_;
    local $/ = $rs;

    ok (1, "Testing for RS $rst");

    {   my $z = IO::Compress::Gzip->new (\$gz) or die $GzipError;
	ok ($z->print ($txt), "print");
	ok ($z->close, "close");
	}

    {   my $z = IO::Uncompress::Gunzip->new (\$gz) or die $GunzipError;
	ok (my $data = $z->getline, "getline");
	is ($data, $txt, "Roundtrip");
	}

    {   local $/ = undef;
	my $z = IO::Uncompress::Gunzip->new (\$gz) or die $GunzipError;
	ok (my $data = $z->getline, "getline \$/ = undef");
	is ($data, $txt, "Roundtrip");
	}

    {   my $z = IO::Uncompress::Gunzip->new (\$gz) or die $GunzipError;
	local $/ = undef;
	ok (my $data = $z->getline, "getline \$/ = undef");
	is ($data, $txt, "Roundtrip");
	}
    }

done_testing;
