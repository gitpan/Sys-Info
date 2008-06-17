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

sub _device_available {
    my $self = shift;
    my @list;
    foreach my $sym ( keys %Sys::Info::Device:: ) {
        next if $sym !~ m{ \A _device_ ([a-zA-Z0-9_]+?) \z}xmsi;
        next if $1 eq 'available';
        push @list, $1;
    }
    return @list;
}

1;

__END__

=head1 NAME

Sys::Info::Device - Information about devices

=head1 SYNOPSIS

    use Sys::Info;
    my $info      = Sys::Info->new;
    my $device    = $info->device( $device_id );
    my @available = $info->device('available');

or

    use Sys::Info::Device;
    my $device    = Sys::Info::Device->new( $device_id );
    my @available = Sys::Info::Device->new('available');

=head1 DESCRIPTION

This is an interface to the available devices such as the C<CPU>.

=head1 METHODS

=head2 new DEVICE_ID

Returns an object to the related device or dies if C<DEVICE_ID> is
bogus or false.

If C<DEVICE_ID> has the value of C<available>, then the names of the
available devices will be returned.

=head1 AUTHOR

Burak G�rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Burak G�rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
