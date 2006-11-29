#!/usr/bin/env perl -w
use strict;
use lib '..'; # to fix editor's syntax checker
BEGIN { do 't/skip.test' or die "Can't include skip.test!" }

eval q{use Test::Pod::Coverage; 1;};

if($@) {
   plan skip_all => "Test::Pod::Coverage required for testing pod coverage";
} else {
   my @mods = qw(
      Sys::Info
      Sys::Info::OS
      Sys::Info::CPU
   );
   plan tests => scalar @mods;
   pod_coverage_ok($_) for @mods;
}
