package Sys::Info::CPU;
use strict;
use vars qw( $VERSION );
use base qw( Sys::Info::Device::CPU );
use Sys::Info qw( _deprecate );

$VERSION = '0.50';

_deprecate({
    msg  => "Use Sys::Info->device('CPU') instead.",
    name => "Sys::Info::CPU",
});

1;

__END__
