use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Note: There is a version string in both
# Fir.pm and Simple.pm

WriteMakefile(
    NAME                => 'PDL::DSP::Fir',
    AUTHOR              => q{John Lapeyre <jlapeyre@cpan.org>},
    VERSION_FROM        => 'lib/PDL/DSP/Fir.pm',
    ABSTRACT_FROM       => 'lib/PDL/DSP/Fir.pm',
    LICENSE => 'perl',
    PL_FILES            => {},
    PM => {
        'lib/PDL/DSP/Fir.pm' => '$(INST_LIBDIR)/Fir.pm',
        'lib/PDL/DSP/Fir/Simple.pm' => '$(INST_LIBDIR)/Fir/Simple.pm',
    },
    PREREQ_PM => {
        'Test::More' => 0,
        'PDL' => 0,
        'PDL::DSP::Windows' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PDL-DSP-* ' },
);


# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
=head1 OVERVIEW

A module for PDL providing some fir filtering.

=cut

EOF

if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open MOD, 'lib/PDL/DSP/Fir.pm' or die "Couldn't open main module";
  open README, '>README.pod'              or die "Couldn't open README.pod";

  print README $POD_header;

  while (<MOD>)
  {
    if (/^=/../^=cut/)
    { print README; }
  }
}
