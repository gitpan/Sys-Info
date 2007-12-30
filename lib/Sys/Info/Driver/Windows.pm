package Sys::Info::Driver::Windows;
use strict;
use vars qw( $VERSION @ISA @EXPORT );
use Exporter ();
use Carp qw( croak );

$VERSION = '0.50';
@ISA     = qw( Exporter );
@EXPORT  = qw( WMI WMI_FOR );

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

1;

__END__
