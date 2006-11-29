#!/usr/bin/env perl -w
BEGIN {
   $^O = 'SomeFakeValue';
   %ENV = ();
}
use strict;

do 't/04-unknown.t' or die "Can not open test 04-unknown.t: $!";

1;
