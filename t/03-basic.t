#!/usr/bin/env perl -w
use strict;
use Sys::Info;
use Data::Dumper;
use Test::More;

BEGIN {
   plan tests => 1;
}

my $BUF  = "\n      %s";

# Just try the interface methods
# ... see if they all exist

my $info = Sys::Info->new;
my $os   = $info->os;
my $cpu  = $info->device('CPU');

print  "\n[Sys::Info]\n";
printf "Perl version     : %s\n"       , $info->perl;
printf "Perl build       : %s\n"       , $info->perl_build;
printf "Perl long version: %s\n"       , $info->perl_long;
printf "HTTP Daemon      : %s\n"       , $info->httpd || 'N/A';
printf "IP Address       : %s\n"       , $os->ip      || 'N/A';

print  "\n[Sys::Info::OS]\n";

printf "OS name          : %s\n"       , $os->name;
printf "OS long name     : %s\n"       , $os->long_name;
printf "OS version       : %s\n"       , $os->version;
printf "OS build         : %s\n"       , $os->build;
printf "OS uptime        : %s\n"       , up($os->uptime)      || 'N/A';
printf "Tick count       : %s\n"       , tick($os->tick_count);
printf "Node name        : %s\n"       , $os->node_name       || 'N/A';
printf "Domain name      : %s\n"       , $os->domain_name     || 'N/A';
printf "Workgroup        : %s\n"       , $os->workgroup       || 'N/A';
printf "User name        : %s\n"       , $os->login_name      || 'N/A';
printf "Real user name   : %s\n"       , $os->login_name_real || 'N/A';
printf "Windows          : %s\n"       , $os->is_windows    ? 'yes' : 'no';
printf "Windows          : %s\n"       , $os->is_win32      ? 'yes' : 'no';
printf "Windows          : %s\n"       , $os->is_win        ? 'yes' : 'no';
printf "Windows NT       : %s\n"       , $os->is_winnt      ? 'yes' : 'no';
printf "Windows 9x       : %s\n"       , $os->is_win95      ? 'yes' : 'no';
printf "Windows 9x       : %s\n"       , $os->is_win9x      ? 'yes' : 'no';
printf "Linux            : %s\n"       , $os->is_linux      ? 'yes' : 'no';
printf "Linux            : %s\n"       , $os->is_lin        ? 'yes' : 'no';
printf "Unknown OS       : %s\n"       , $os->is_unknown    ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_root       ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_admin      ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_admin_user ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_adminuser  ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_root_user  ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_super_user ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_superuser  ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_su         ? 'yes' : 'no';
printf "Logon Server     : %s\n"       , $os->logon_server    || 'N/A';
printf "Time Zone        : %s\n"       , $os->tz              || 'N/A';
printf "File system      : $BUF\n"     , dumper( FS   => { $os->fs   } );
printf "OS meta          : $BUF\n"     , dumper( META => { $os->meta } );

print  "\n[Sys::Info::CPU]\n";

printf "CPU Name         : %s\n"       , scalar($cpu->identify) || 'N/A';
printf "CPU Speed        : %s MHz\n"   , $cpu->speed            || 'N/A';
printf "CPU load average : %s\n"       , $cpu->load             || 'N/A';
printf "Number of CPUs   : %s\n"       , $cpu->count            || 'N/A';
printf "CPU probe        : $BUF\n"     , dumper(CPU => $cpu->identify);

# BIOS ???

ok(1);

#------------------------------------------------------------------------------#

sub dumper {
   my $n   = shift;
   my $ref = (@_ == 1) ? shift : \@_;
   Data::Dumper->Dump([$ref], ['*'.$n])
}

sub up {
   my $up = shift || return 0;
   scalar(localtime $up);
}

sub tick {
   my $tick = shift || return 0;
   eval { require Time::Elapsed; };
   return sprintf( "%.2f days", $tick / (60*60*24) ) if $@;
   return Time::Elapsed::elapsed( $tick );
}

1;
