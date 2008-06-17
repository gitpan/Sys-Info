#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Sys::Info;

my $info = Sys::Info->new;
my $cpu  = $info->device('CPU');

# interface test
my @id_cpu  = $cpu->identify;
my $id_cpu  = $cpu->identify;
my $total   = $cpu->count;
my $ht      = $cpu->ht;
my $ht2     = $cpu->hyper_threading;
my $mhz     = $cpu->speed;
my $load_00 = $cpu->load(  );
my $load_01 = $cpu->load( 1);
my $load_05 = $cpu->load( 5);
my $load_10 = $cpu->load(10);

foreach my $var (
    $id_cpu,
    $total,
    $ht,
    $ht2,
    $mhz,
    $load_00,
    $load_01,
    $load_05,
    $load_10,
) {
   $var = 'undef' if not defined $var;
}

@id_cpu = ('false') if ! @id_cpu;

diag <<"CPU_TEST";
    \@id_cpu  @id_cpu
    \$id_cpu  $id_cpu
    \$total   $total
    \$ht      $ht
    \$ht2     $ht2
    \$mhz     $mhz
    \$load_00 $load_00
    \$load_01 $load_01
    \$load_05 $load_05
    \$load_10 $load_10
CPU_TEST

ok(1);

1;
