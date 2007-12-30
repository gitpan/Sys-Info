#!/usr/bin/env perl -w
use strict;
use vars qw($ERROR);
use Test::More;

BEGIN {
   eval q{ use Test::Pod 1.00; };
   $ERROR = $@;
}
   
if($ERROR) {
   plan skip_all => "Test::Pod 1.00 required for testing POD";
} else {
   all_pod_files_ok();
}
