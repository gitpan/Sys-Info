package Sys::Info::Driver::Windows;
use strict;
use vars qw( $VERSION @ISA @EXPORT );
use Exporter ();
use Carp qw( croak );
use constant B24_DIGITS => qw( B C D F G H J K M P Q R T V W X Y 2 3 4 6 7 8 9 );

$VERSION = '0.50';
@ISA     = qw( Exporter );
@EXPORT  = qw( WMI WMI_FOR HASAPI decode_serial_key );

my $HASAPI;

sub WMI {
    my $WMI = Win32::OLE->GetObject("WinMgmts:") || return; 
    croak Win32::OLE->LastError() if Win32::OLE->LastError() != 0;
    return $WMI;
}

sub WMI_FOR {
    my $WMI = WMI() || return;
    my $ID  = shift || die "No WMI Class specified";
    my $O   = $WMI->InstancesOf( $ID ) || return;
    croak Win32::OLE->LastError() if Win32::OLE->LastError() != 0;
    return $O;
}

sub HASAPI {
    return $HASAPI if defined $HASAPI;
    local $@;
    local $SIG{__DIE__};
    eval { require Win32::API; };
    warn "Error loading Win32::API: $@" if $@;
    $HASAPI = $@ ? 0 : 1;
    return $HASAPI;
}

sub decode_serial_key {
    # Modified from:
    #     http://www.perlmonks.org/?node_id=497616
    #     (c) Original code: William Gannon
    #     (c) Modifications: Charles Clarkson
    my $key     = shift || die "Key is missing";
    my @encoded = ( unpack 'C*', $key )[ reverse 52 .. 66 ];
    use integer;

    my $quotient = sub {
        my( $index, $encoded ) = @_;
        my $dividend = $index * 256 ^ $encoded;
        # return modulus and integer quotient
        return( $dividend % 24, $dividend / 24 );
    };

    my @indices;
    foreach my $i ( 0 .. 24 ) {
        my $index = 0;
        foreach my $j (@encoded) { # Shift off remainder
            ( $index, $j ) = $quotient->( $index, $j );
        }
        unshift @indices, $index;
    }

    # translate base 24 "digits" to characters
    my $cd_key = join '', (B24_DIGITS)[ @indices ];

    # Add seperators and return
    return join '-', $cd_key =~ /(.{5})/g;
}


1;

__END__

=head1 NAME

Sys::Info::Driver::Windows - Windows driver for Sys::Info

=head1 SYNOPSIS

    use Sys::Info::Driver::Windows;

=head1 DESCRIPTION

This is the main module in the C<Windows> driver collection.

=head1 METHODS

None.

=head1 FUNCTIONS

The following functions will be automatically exported when the module
is used.

=head2 WMI

Returns the C<WMI> object.

=head2 WMI_FOR CLASS

Return the WMI object of the supplied C<WMI Class> name.

=head2 HASAPI

Returns true is C<Win32::API> is installed on the system.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
