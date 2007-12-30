#!/usr/bin/env perl -w
use strict;
BEGIN {
   $^O = 'SomeFakeValue';
   %ENV = ();
}

do 't/04-unknown.t' or die "Can not open test 04-unknown.t: $!";

1;
