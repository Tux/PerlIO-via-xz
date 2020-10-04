#!/pro/bin/perl

package PerlIO::via::gzip;

use 5.12.0;
use warnings;

use PerlIO;
use IO::Compress::Gzip qw(:constants);
use IO::Uncompress::Gunzip;
use Carp;

our $VERSION			= "0.03";
our $COMPRESSION_LEVEL		= Z_DEFAULT_COMPRESSION;
our $COMPRESSION_STRATEGY	= Z_DEFAULT_STRATEGY;
our $BLOCK_SIZE			= 4096;
our $INSTANCE			= 128;

sub PUSHED { 
    my ($class, $mode) = @_;
    #no strict qw(refs);
    my $self = { 
        instance => $INSTANCE++,
        mode     => $mode =~ s{\+//}{}r,
	};
    bless $self, $class;
    } # PUSHED

# open hook
sub FILENO {
    my ($self, $fh) = @_;
    unless (defined $self->{inited}) {
	my $via = grep m/via/ => PerlIO::get_layers ($fh);
	my $compress = ($self->{mode} =~ /w|a/ and !$via) ||
		       ($self->{mode} =~ /r/   and  $via);
	$self->{fileno} = fileno ($fh); # nec. to kick fileno hooks
	$self->{inited} = 1;
	if ($compress) {
	    $self->{gzip} = IO::Compress::Gzip->new ($fh,
		AutoClose => 1,
		Level     => $COMPRESSION_LEVEL,
		Strategy  => $COMPRESSION_STRATEGY,
		) or croak "via(gzip) [OPEN]: Couldn't create compression stream";
	    $self->{gzip}->autoflush (1);
	    }
	else {
	    $self->{gunzip} = IO::Uncompress::Gunzip->new ($fh,
		BlockSize => $BLOCK_SIZE
		) or croak "via(gzip) [OPEN]: Couldn't create decompression stream";
	    }
	}
    $self->{fileno};
    } # FILENO

sub FILL {
    my ($self, $fh) = @_;
    return $self->Readline ($fh);
    } # FILL

sub Readline {
    my $self = shift;
    $self->{gzip}	and return $self->{gzip}->getline;
    $self->{gunzip}	and return $self->{gunzip}->getline;
    croak "via(gzip) [FILL]: handle not initialized";
    } # ReadLine

sub WRITE {
    my ($self, $buf, $fh) = @_;
    return $self->Write ($fh, $buf);
    } # WRITE

sub Write {
    my ($self, $fh, $buf) = @_;
    $self->{gunzip}	and return $self->{gunzip}->write($buf);
    $self->{gzip}	and return $self->{gzip}->print($buf);
    croak "via(gzip) [WRITE]: handle not initialized";
    } # Write

sub FLUSH {
    my ($self, $fh) = @_;
    $self->{inited} or return -1; # not open yet
    $fh and $fh->flush;
    if ($self->{gzip}) {
        $self->{gzip}->flush;
        # to get a valid gzip file, the Gzip handle must 
        # be closed before the source handle. 
        # if FLUSH is called on via handle close, 
        # the source handle is closed before we 
        # can get to it in via::gzip::CLOSE.
        # So we are closing the Gzip handle here.
        $self->{gzip}->close;
        1;
        }
    return 0;
    } # FLUSH

sub CLOSE {
    my ($self, $fh) = @_;
    $self->{inited} or  return -1; # not open yet

    $self->{gunzip} and $self->{gunzip}->close;

    # the $self->{gzip} handle was already flushed and 
    # closed by FLUSH

    return $fh ? $fh->close : 0;
    } # CLOSE

1;
__END__

=pod 

=head1 NAME

PerlIO::via::gzip - PerlIO layer for gzip (de)compression

=head1 SYNOPSIS

 # compress
 open  $cfh, ">:via(gzip)", "stuff.gz";
 print $cfh @stuff;

 # decompress
 open  $fh, "<:via(gzip)", "stuff.gz";
 while (<$fh>) {
     ...
     }

=head1 DESCRIPTION

This module provides a PerlIO layer for transparent gzip de/compression,
using L<IO::Compress::Gzip> and L<IO::Uncompress::Gunzip>. 

=head1 Changing compression parameters

On write, compression level and strategy default to the defaults specified in 
L<IO::Compress::Gzip>. To hack these, set

 $PerlIO::via::gzip::COMPRESSION_LEVEL

and

 $PerlIO::via::gzip::COMPRESSION_STRATEGY

to the desired constants, as imported from L<IO::Compress::Gzip>.

=head1 NOTE

When a C<PerlIO::via::gzip> write handle is flushed, the underlying
IO::Compress::Gzip handle is flushed and closed. This appears to be
necessary for getting a valid gzip file when a C<PerlIO::via::gzip>
write handle is closed. See comment in the FLUSH source.

=head1 SEE ALSO

L<PerlIO|perlio>, L<PerlIO::via>, L<IO::Compress::Gzip>, L<IO::Uncompress::Gunzip>

=head1 AUTHOR - Mark A. Jensen

 Email maj -at- cpan -dot- org
 http://fortinbras.us

=cut
