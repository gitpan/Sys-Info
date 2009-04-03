#!/usr/bin/env perl -w
use strict;
use Sys::Info::Constants qw(OSID);
use Test::Sys::Info;

driver_ok( OSID );
