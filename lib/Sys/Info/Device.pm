package Sys::Info::Device;
use strict;
use vars qw($VERSION);
use Carp qw( croak );
use Sys::Info qw( OSID );

$VERSION = '0.50';

sub new {
    my $class  = shift;
    my $device = shift || croak "Device ID is missing";
    my $self   = {};
    bless $self, $class;

    my $method = '_device_' . lc($device);
    if ( ! $self->can( $method ) ) {
        croak "Bogus device ID: $device";
    }
    return $self->$method( @_ ? (@_) : () );
}

sub _device_cpu {
    my $self = shift;
    require Sys::Info::Device::CPU;
    return  Sys::Info::Device::CPU->new(@_);
}

sub _device_bios {
    my $self = shift;
    require Sys::Info::Device::BIOS;
    return  Sys::Info::Device::BIOS->new(@_);
}

1;

__END__
