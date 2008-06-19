package Sys::Info::Driver::Linux;
use strict;
use vars qw( $VERSION @ISA @EXPORT );
use Exporter ();

$VERSION = '0.50';
@ISA     = qw( Exporter );
@EXPORT  = qw( proc );

use constant proc => {
    loadavg => '/proc/loadavg', # average cpu load
    cpuinfo => '/proc/cpuinfo', # cpu information

    fstab   => '/etc/fstab',    # for filesystem type of the current disk
    uptime  => '/proc/uptime',  # uptime file
    version => '/proc/version', # os version
    resolv  => '/etc/resolv.conf',
    #issue   => '/etc/issue',
};

1;

__END__
