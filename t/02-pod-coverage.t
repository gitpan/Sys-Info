#!/usr/bin/env perl -w
use strict;
use Test::More;

eval q{use Test::Pod::Coverage; 1;};

if($@) {
   plan skip_all => "Test::Pod::Coverage required for testing pod coverage";
} else {
   my @mods = (
      { class => 'Sys::Info', opt => { trustme => [qw/cpu/]} },
      { class => 'Sys::Info::OS' },
      { class => 'Sys::Info::Device::CPU' },
   );
   plan tests => scalar @mods;
   pod_coverage_ok($_->{class}, $_->{opt} ? ($_->{opt}) : ()) for @mods;
}
