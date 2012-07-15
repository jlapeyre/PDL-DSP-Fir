package PDL::DSP::Fir;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.001';

use base 'Exporter';

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::Options;
use PDL::Constants qw(PI);
use PDL::DSP::Windows;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( firwin ir_sinc ir_hisinc spectral_invert spectral_reverse );

$PDL::onlinedoc->scan(__FILE__) if $PDL::onlinedoc;

=head1 NAME

PDL::DSP::Fir - Finite impulse response filter kernels.

=head1 SYNOPSIS

       use PDL;
       use PDL::DSP::Fir;

=head1 DESCRIPTION

The module provides routines to create finite impulse
response (FIR) filter kernels.  For a simple interface for
filtering with this module, see L<PDL::DSP::Fir::Simple>.
The routine L</firwin> returns a filter kernel constructed
from windowed sinc functions. Available filters are lowpass,
highpass, bandpass, and bandreject. The window functions are
in the module L<PDL::DSP::Windows>.

Below, the word B<order> refers to the number of elements in the filter
kernel.

No functions are exported.

=head1 FUNCTIONS

=head2 firwin

=head3 Usage

 $kern = firwin({OPTIONS});

Returns a filter kernel (a finite impulse response function)
to be convolved with data. The kernel is built from windowed
sinc functions. With the option C<type =E<gt> 'window'> no
sinc is used, rather the kernel is just the window.

=head3 OPTIONS

=over

=item N   

order of filter.

=item type  

Filter type. Default: lowpass. One of lowpass, highpass, bandpass, 
bandstop, window. Aliases for bandstop are bandreject and notch.

=item fc   

Cutoff frequency for low- and highpass. Must be a number between
0 and 1, which expresses a fraction of the Nyquist frequency.
No default value.

=item fclo, fchi  

Lower and upper cutoff frequencies for bandpass and bandstop filters.
No default values.

=back

All other options to C<firwin> are passed to the function 
L<PDL::DSP::Windows/window>.

=cut

sub firwin {
    my ($iopts) = @_;
    my $opt = new PDL::Options(
        {
            N => undef,
            type => 'lowpass',
            win => undef,
            fc => undef,
            fclo => undef,
            fchi => undef,
        });
    my $opts = $opt->options($iopts);
    my $winopts = { N => $opts->{N} };
    if (defined $opts->{win} ) {
        my $w = $opts->{win};
        if ( ref $w ) {
            foreach my $wkey (keys %{$w}) {
                $winopts->{$wkey} = $w->{$wkey};
            }
        }
        else {
            $winopts->{NAME} = $w;
        }
    }
    my $type = $opts->{type};
    my $win = PDL::DSP::Windows::window($winopts);
    my ($ir);
    $ir = ir_sinc($opts->{fc},$opts->{N}), return $ir * $win 
        if ($type eq 'lowpass');
    $ir = ir_sinc($opts->{fc},$opts->{N}), return spectral_invert($ir * $win)
        if ($type eq 'highpass');        
    return $win/$win->sum if ($type eq 'window');
    if ($type eq 'bandpass') {
        my $ir1 = ir_sinc($opts->{fclo},$opts->{N});
        my $ir2 = ir_sinc($opts->{fchi},$opts->{N});
        my $fir1 = $ir1 * $win;
        my $fir2 = spectral_invert($ir2 * $win);
        return spectral_invert($fir1 + $fir2);
    }
    if ($type eq 'bandstop' or $type eq 'bandreject' or $type eq 'notch') {
        my $ir1 = ir_sinc($opts->{fclo},$opts->{N});
        my $ir2 = ir_sinc($opts->{fchi},$opts->{N});
        my $fir1 = $ir1 * $win;
        my $fir2 = spectral_invert($ir2 * $win);
        return $fir1 + $fir2;
    }
    barf "PDL::DSP::FIR::firwin: Unknown impulse response '$type'\n";
}

=pod

The following three functions are called by the C<firwin>, but
may also be useful by themselves, for instance, to construct more
complicated filters.

=head2 ir_sinc

  $sinc = ($f_cut, $N);

Return an C<$N> point sinc function with cutoff frequency C<$f_cut>.
C<$f_cut> must be between 0 and 1. With 1 being Nyquist freq.

=cut

sub ir_sinc {
    my ($f_cut,$L) = @_;
    my $c = PI*$f_cut;
    my $x = sequence($L) - ($L-1)/2;
    my $mid = int($L/2);
    my $res = sin($c*$x)/$x;
    $res($mid) .= $c; # fix nan at x=0
    $res/PI;
}

=head2 spectral_invert

  $fir_inv = spectral_invert($fir);

Return a fir function whose spectrum is the additive inverse
wrt 1 of the spectrum of fir function C<$fir>.

=cut

sub spectral_invert {
    my ($fir) = @_;
    my $L = $fir->nelem;
    barf "spectral_invert: L=$L is not odd\n" if ($L % 2 == 0);
    my $mid = ($L-1)/2;
    my $ifir = -$fir;
    $ifir($mid) += 1;
    $ifir;
}

=head2 spectral_reverse

  $fir_rev = spectral_reverse($fir);

Return a fir function whose spectrum is the reverse
of the spectrum fir function C<$fir>. That is, the
spectrum is mirrored about the center frequency.
 
=cut

sub spectral_reverse {
    my ($fir) = @_;
    my $ofir = $fir->copy;
    $ofir(0:-1:2) *= -1;
    $ofir;
}

=head1 AUTHOR

John Lapeyre, C<< <jlapeyre at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 John Lapeyre.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of PDL::DSP::Fir
