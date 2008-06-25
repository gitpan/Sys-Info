#!/usr/bin/env perl -w
use strict;
BEGIN {
   $^O = 'SomeFakeValue';
   %ENV = ();
}

require 't/04-unknown.t';

1;
