package Sys::Info::Constants;
use strict;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );
use Sys::Info qw( OSID );
use Carp qw( croak );
use Exporter ();
use constant DCPU_LOAD_LAST_01 => 0;
use constant DCPU_LOAD_LAST_05 => 1;
use constant DCPU_LOAD_LAST_10 => 2;
use constant DCPU_LOAD         => (0..2);

$VERSION = '0.50';
@ISA     = qw(Exporter);

%EXPORT_TAGS = (
   device_cpu => [qw/
                     DCPU_LOAD_LAST_01
                     DCPU_LOAD_LAST_05
                     DCPU_LOAD_LAST_10
                     DCPU_LOAD
                  /],
);

$EXPORT_TAGS{all} = [
    map { @{ $_ } } values %EXPORT_TAGS
];

@EXPORT_OK = @{ $EXPORT_TAGS{all} };

1;

__END__


use Sys::Info::Constants -device => 'cpu';
use Sys::Info::Constants -group   => 'cpu';
