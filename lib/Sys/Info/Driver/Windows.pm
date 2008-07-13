package Sys::Info::Driver::Windows;
use strict;
use vars qw( $VERSION @ISA @EXPORT );
use Exporter ();
use Carp qw( croak );
use Sys::Info::Constants qw( WIN_B24_DIGITS );

$VERSION = '0.60';
@ISA     = qw( Exporter );
@EXPORT  = qw( WMI WMI_FOR decode_serial_key );

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
    my $cd_key = join '', (WIN_B24_DIGITS)[ @indices ];

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

Returns the WMI object for the supplied C<WMI Class> name.

=head2 decode_serial_key KEY

Decodes the base24 encoded C<KEY>.

=head1 SEE ALSO

L<http://www.perlmonks.org/?node_id=497616>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
