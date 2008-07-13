package Sys::Info::Driver::Windows::OS::Editions;
use strict;
use vars qw( $VERSION );

use Sys::Info::Driver::Windows;
use Sys::Info::Driver::Windows::XS qw( :metrics );

$VERSION = '0.60';

my %VISTA_EDITION = ( # OK
   0x00000006 => q{Business Edition},
   0x00000010 => q{Business N Edition},
   0x00000004 => q{Enterprise Edition},
   0x00000002 => q{Home Basic Edition},
   0x00000005 => q{Home Basic N Edition},
   0x00000003 => q{Home Premium Edition},
   0x0000000B => q{Starter Edition},
   0x00000001 => q{Ultimate Edition},
);

my %SERVER08_EDITION = ( # OK
   0x00000012 => q{Cluster Server Edition},
   0x00000008 => q{Datacenter Edition Full Installation}, # Windows Server ...
   0x0000000C => q{Datacenter Edition Core Installation}, # Windows Server ...
   0x0000000A => q{Enterprise Edition Full Installation}, # Windows Server ...
   0x0000000E => q{Enterprise Edition Core Installation}, # Windows Server ...
   0x0000000F => q{Enterprise Edition For Itanium Based Systems}, # Windows Server ...
   0x00000013 => q{Home Server Edition},
   0x00000018 => q{Server For Small Business Edition},
   0x00000009 => q{Small Business Server},
   0x00000019 => q{Small Business Server Premium Edition},
   0x00000007 => q{Server Standard Edition Full Installation},
   0x0000000D => q{Server Standard Edition Core Installation},
   0x00000017 => q{Storage Server Enterprise Edition},
   0x00000014 => q{Storage Server Express Edition},
   0x00000015 => q{Storage Server Standard Edition},
   0x00000016 => q{Storage Server Workgroup Edition},
   0x00000011 => q{Web Server Edition},
);

sub _cpu_arch {
    my $self = shift;
    require Sys::Info;
    my $info = Sys::Info->new;
    my $cpu  = $info->device( 'CPU' );
    foreach my $cpu ( $cpu->identify ) {
        # get the first available one
        return $cpu->{architecture} if $cpu->{architecture};
    }
    return;
}

sub _xp_or_03 {
    my $self = shift;
    my $edition_ref = shift;
    my $osname_ref  = shift;
    my $OSV         = shift;

    my $mask   = $OSV->{RAW}{SUITEMASK};
    my $pt     = $OSV->{RAW}{PRODUCTTYPE};
    my $arch   = $self->_cpu_arch || '';
    my $metric = GetSystemMetrics(SM_SERVERR2);

    $$osname_ref = 'Windows Server 2003';

    if ( $mask & 0x00000080 ) {
        if ( $metric ) {
            $$edition_ref = $arch =~ m{X86}i   ? 'R2 Datacenter Edition'
                          : $arch =~ m{AMD64}i ? 'R2 x64 Datacenter Edition'
                          :                      'unknown'
                          ;
        }
        else {
            $$edition_ref = $arch =~m{X86}i     ? 'Datacenter Edition'
                          : $arch =~m{AMD64}i   ? 'Datacenter x64 Edition'
                          : $arch =~m{IA64}i    ? 'Datacenter Edition Itanium'
                          :                       'unknown'
                          ;
        }
    }
    elsif ( $mask & 0x00000002 ) {
        if ( $metric ) {
            $$edition_ref = $arch =~ m{X86}i    ? 'R2 Enterprise Edition'
                          : $arch =~ m{AMD64}i  ? 'R2 x64 Enterprise Edition'
                          :                       'unknown'
                          ;
        }
        else {
            $$edition_ref = $arch =~ m{X86}i    ? 'Enterprise Edition'
                          : $arch =~ m{AMD64}i  ? 'Enterprise x64 Edition'
                          : $arch =~ m{IA64}i   ? 'Enterprise Edition Itanium'
                          :                       'unknown'
                          ;
        }
    }
    else {
        if ( $metric ) {
            $$edition_ref = $arch =~ m{X86}i   ? 'R2 Standard Edition'
                          : $arch =~ m{AMD64}i ? 'R2 x64 Standard Edition'
                          :                      'unknown'
                          ;
        }
        elsif ( $pt > 1 ) {
            $$edition_ref = $arch =~ m{X86}i   ? 'Standard Edition'
                          : $arch =~ m{AMD64}i ? 'Standard x64 Edition'
                          :                      'unknown'
                          ;
        }
        elsif ( $pt == 1 ) {
            $$osname_ref  = 'Windows XP';
            $$edition_ref = $arch =~ m{IA64}i  ? '64 bit Edition Version 2003'
                          : $arch =~ m{AMD64}i ? 'Professional x64 Edition'
                          :                      'unknown'
                          ;
        }
        else {
            $$edition_ref = 'unknown';
        }
    }
}

sub _xp_editions {
    my $self = shift;
    my $edition_ref = shift;
    my $osname_ref  = shift;
    my $OSV         = shift;
    my $arch        = $self->_cpu_arch;

    $$osname_ref  = 'Windows XP';
    $$edition_ref = GetSystemMetrics(SM_TABLETPC)    ? 'Tablet PC Edition'
                  : GetSystemMetrics(SM_MEDIACENTER) ? 'Media Center Edition'
                  : GetSystemMetrics(SM_STARTER)     ? 'Starter Edition'
                  : $arch =~ m{x86}i                 ? 'Professional'
                  : $arch =~ m{IA64}i                ? '64-bit Edition for Itanium systems'
                  :                                    ''
                  ;
}

sub _2k_03_xp {
    my $self        = shift;
    my $edition_ref = shift;
    my $osname_ref  = shift;
    my $OSV         = shift;

    my $mask = $OSV->{RAW}{SUITEMASK};
    my $pt   = $OSV->{RAW}{PRODUCTTYPE};

    $$osname_ref = 'Windows 2000';

    if ( $mask & 0x00000080 ) {
        $$edition_ref = 'Datacenter Server';
    }
    elsif ( $mask & 0x00000002) {
        $$edition_ref = 'Advanced Server';
    }
    elsif (! $mask && $pt == 1 ) {
        $$edition_ref = 'Professional';
    }
    elsif (! $mask && $pt > 1 ) {
        $$edition_ref = 'Server';
    }
    elsif ( $mask & 0x00000400 ) {
        $$osname_ref  = 'Windows Server 2003';
        $$edition_ref = GetSystemMetrics(SM_SERVERR2) ? 'R2 Web Edition'
                                                      : 'Web Edition';
    }
    elsif ( $mask & 0x00004000) {
        $$osname_ref  = 'Windows Server 2003';
        $$edition_ref = GetSystemMetrics(SM_SERVERR2) ? 'R2 Compute Cluster Edition'
                                                      : 'Compute Cluster Edition';
    }
    elsif ( $mask & 0x00002000) {
        $$osname_ref  = 'Windows Server 2003';
        $$edition_ref = GetSystemMetrics(SM_SERVERR2) ? 'R2 Storage'
                                                      : 'Storage';
    }
    elsif ($mask & 0x00000040 ) {
        $$osname_ref  = 'Windows XP';
        $$edition_ref = 'Embedded';
    }
    elsif ($mask & 0x00000200) {
        $$osname_ref  = 'Windows XP';
        $$edition_ref = 'Home Edition';
    }
    else {
        warn "Unable to identify this Windows version";
    }
}

sub _vista_or_08 {
    my $self        = shift;
    my $edition_ref = shift;
    my $osname_ref  = shift;

    # fall-back
    if ( my $WMI_OS = WMI_FOR('Win32_OperatingSystem') ) {
        my $item    = ( in $WMI_OS )[0];
        my $SKU     = $item->OperatingSystemSKU();
        my $caption = $item->Caption();
        if ( my $vista = $VISTA_EDITION{ $SKU } ) {
            $$edition_ref = $vista;
            $$osname_ref  = 'Windows Vista';
        }
        elsif ( my $ws08 = $SERVER08_EDITION{ $SKU } ) {
            $$edition_ref = $ws08;
            $$osname_ref  = 'Windows Server 2008'; # oh yeah!
        }
        else {
            warn "Unable to identify this Windows version. Marking as Vista";
            $$osname_ref = 'Windows Vista';
        }
    }
}

1;

__END__

=head1 NAME

Sys::Info::Driver::Windows::OS::Editions - Interface to identify Windows editions

=head1 SYNOPSIS

None. Used internally.

=head1 DESCRIPTION

Although there are not much Windows versions, there are ridiculously lots of
editions of Windows versions after Windows 2000. This module uses C<WMI>,
C<GetSystemMetrics> and CPU architecture to define the correct operating
system name and edition.

=head1 SEE ALSO

L<Sys::Info>,
L<Sys::Info::Driver::Windows::XS>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
