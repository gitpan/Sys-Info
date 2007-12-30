#!/usr/bin/env perl -w
use strict;
BEGIN { $^O = 'SomeFakeValue' }
use Test;
use Sys::Info;
use Data::Dumper;

BEGIN {
   plan tests => 1;
}

open TEST, 't/03-basic.t' or die "Can not open test 03-basic.t: $!";
my $test;
{
   local $/;
   $test = <TEST>;
}
close TEST;

$test =~ s<BEGIN\s+{.+?}><>s;
$test =~ s<use Test.*;><>s;
$test =~ s<ok\(.+?\)><>gs;
eval $test;
die "Can not run test: $@" if $@;

ok(1);

1;
