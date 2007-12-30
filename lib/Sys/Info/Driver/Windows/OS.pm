package Sys::Info::Driver::Windows::OS;
use strict;
use vars qw( $VERSION );
use Win32;
use Win32::OLE qw( in );
use Sys::Info::Driver::Windows;
use Sys::Info::Driver::Windows::OS::Net;
use Carp qw( croak );

# Win32::IsAdminUser(): Perl 5.8.3 Build 809 Monday, Feb 2, 2004
use constant is_root => defined &Win32::IsAdminUser ? Win32::IsAdminUser()
                     :  Win32::IsWin95()            ? 1
                     :                                0
                     ;
use constant WMIDATE_TMPL => 'A4 A2 A2 A2 A2 A2';

$VERSION = '0.50';

my %OSVERSION;  # see _populate_osversion
my %FILESYSTEM; # see _populate_fs
my $NET = 'Sys::Info::Driver::Windows::OS::Net';

BEGIN {
    *is_win9x = *is_win95 = sub{ Win32::IsWin95() };
    *is_winnt             = sub{ Win32::IsWinNT() };
}

sub product_type { shift->_populate_osversion(); $OSVERSION{RAW}->{PRODUCTTYPE} }
sub name         { shift->_populate_osversion(); $OSVERSION{NAME}               }
sub long_name    { shift->_populate_osversion(); $OSVERSION{LONGNAME}           }
sub version      { shift->_populate_osversion(); $OSVERSION{VERSION}            }
sub build        { shift->_populate_osversion(); $OSVERSION{RAW}->{BUILD} || 0  }
sub uptime       {                               time - shift->tick_count       }
sub node_name    { Win32::NodeName()                     }
sub domain_name  { is_win95() ? '' : Win32::DomainName() }

sub tick_count {
    my $tick = Win32::GetTickCount();
    return $tick ? $tick / 1000 : 0; # in miliseconds
}

sub login_name { Win32::LoginName() }

sub login_name_real {
    my $self = shift;
    my $name = $self->login_name || return '';
    my $real = $NET->user_fullname($name);
    return $real || $name;
}

sub logon_server {
    my $self = shift;
    my $name = $self->login_name || return '';
    return $NET->user_logon_server( $name );
}

sub fs {
    my $self = shift;
    $self->_populate_fs();
    return %FILESYSTEM;
}

sub tz {
    foreach my $objItem ( in WMI_FOR("Win32_TimeZone") ) {
        return $objItem->Caption;
    }
}

sub meta { # linux ???
    my $self = shift;
    my $id   = shift;
    my %info;

    foreach my $objOS ( in WMI_FOR('Win32_OperatingSystem') ) {
        $info{manufacturer}              = $objOS->Manufacturer;
        $info{build_type}                = $objOS->BuildType;
        $info{owner}                     = $objOS->RegisteredUser;
        $info{organization}              = $objOS->Organization;
        $info{product_id}                = $objOS->SerialNumber;
        $info{install_date}              = $self->_wmidate_to_unix(
                                                $objOS->InstallDate
                                            );
        $info{boot_device}               = $objOS->BootDevice;
        $info{time_zone}                 = $objOS->CurrentTimezone;
        $info{physical_memory_total}     = $objOS->TotalVisibleMemorySize;
        $info{physical_memory_available} = $objOS->FreePhysicalMemory;
        $info{page_file_total}           = $objOS->TotalVirtualMemorySize;
        $info{page_file_available}       = $objOS->FreeVirtualMemory;
        # windows specific
        $info{windows_dir}               = $objOS->WindowsDirectory;
        $info{system_dir}                = $objOS->SystemDirectory;
        # ????
        $info{locale}                    = $objOS->Locale;
        last;
    }

    foreach my $objCS ( in WMI_FOR('Win32_ComputerSystem') ) {
       $info{system_manufacturer} = $objCS->Manufacturer;
       $info{system_model}        = $objCS->Model;
       $info{system_type}         = $objCS->SystemType;
       $info{domain}              = $objCS->Domain;
       last;
    }

    foreach my $objPF ( in WMI_FOR('Win32_PageFileUsage') ) {
        $info{page_file_path} = $objPF->Name;
        last;
    }

    return %info if ! $id;

    my $lcid = lc $id;
    if ( ! exists $info{ $lcid } ) {
        croak "$id meta value is not supported by the underlying Operating System";
    }
    return $info{ $lcid };
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _wmidate_to_unix {
    my $self  = shift;
    my $thing = shift || return;
    my($date, $junk) = split /\./, $thing;
    my($year, $mon, $mday, $hour, $min, $sec) = unpack WMIDATE_TMPL, $date;
    require Time::Local;
    return Time::Local::timelocal( $sec, $min, $hour, $mday, $mon-1, $year );
}

sub _populate_fs {
    return if %FILESYSTEM;
    my $self  = shift;
    my($FSTYPE, $FLAGS, $MAXCOMPLEN) = Win32::FsType();
    if ( !$FSTYPE && Win32::GetLastError() ) {
        warn "Can not fetch file system information: $^E";
        return;
    }
    my %flag = (
        case_sensitive     => 0x00000001,  #'supports case-sensitive filenames',
        preserve_case      => 0x00000002,  #'preserves the case of filenames',
        unicode            => 0x00000004,  #'supports Unicode in filenames',
        acl                => 0x00000008,  #'preserves and enforces ACLs',
        file_compression   => 0x00000010,  #'supports file-based compression',
        disk_quotas        => 0x00000020,  #'supports disk quotas',
        sparse             => 0x00000040,  #'supports sparse files',
        reparse            => 0x00000080,  #'supports reparse points',
        remote_storage     => 0x00000100,  #'supports remote storage',
        compressed_volume  => 0x00008000,  #'is a compressed volume (e.g. DoubleSpace)',
        object_identifiers => 0x00010000,  #'supports object identifiers',
        efs                => 0x00020000,  #'supports the Encrypted File System (EFS)',
    );
    my @fl;
    if ($FLAGS) {
        foreach my $f (keys %flag) {
            push @fl, $f => $flag{$f} & $FLAGS ? 1 : 0;
        }
    }
    push @fl, max_file_length => $MAXCOMPLEN if $MAXCOMPLEN;
    push @fl, filesystem      => $FSTYPE     if $FSTYPE; # NTFS/FAT/FAT32
    %FILESYSTEM = (@fl);
    return;
}

sub _populate_osversion {
    return if %OSVERSION;
    my $self = shift;
    # Win32::GetOSName() is not reliable.
    # Since, an older release will not have any idea about XP or Vista
    my(
        $STRING , $MAJOR  , $MINOR    , $BUILD      , $ID, # All
        $SPMAJOR, $SPMINOR, $SUITEMASK, $PRODUCTTYPE       # NT 4 SP6 and later
    ) = Win32::GetOSVersion();

    $MAJOR = 0 if not defined $MAJOR;
    $MINOR = 0 if not defined $MINOR;

    my $t = sub { $MAJOR == $_[0] && $MINOR == $_[1] };
    my $j = join '.', $ID, $MAJOR, $MINOR;
    my $os;

       if ( $ID == 0 ) {        $os = 'Win32s'              }
    elsif ( $ID == 1 ) {
           if ( $t->(4,  0) ) { $os = 'Windows 95'          }
        elsif ( $t->(4, 10) ) { $os = 'Windows 98'          }
        elsif ( $t->(4, 90) ) { $os = 'Windows Me'          }
        else                  { $os = "Windows 9x $j"       }
    }
    elsif ( $ID == 2 ) {
           if ( $t->(3, 51) ) { $os = 'Windows NT 3.51'     }
        elsif ( $t->(4,  0) ) { $os = 'Windows NT 4'        }
        elsif ( $t->(5,  0) ) { $os = 'Windows 2000'        }
        elsif ( $t->(5,  1) ) { $os = 'Windows XP'          }
        elsif ( $t->(5,  2) ) { $os = 'Windows Server 2003' }
        elsif ( $t->(6,  0) ) { $os = 'Windows Vista'       }
        else                  { $os = "Windows NT $j"       }
    }
    else                      { $os = "Windows $j"          }

    %OSVERSION = (
        NAME     => $os,
        LONGNAME => '', # will be set below
        VERSION  => $j,
        RAW      => {
                        STRING      => $STRING,
                        MAJOR       => $MAJOR,
                        MINOR       => $MINOR,
                        BUILD       => $BUILD,
                        ID          => $ID,
                        SPMAJOR     => $SPMAJOR,
                        SPMINOR     => $SPMINOR,
                        PRODUCTTYPE => $self->_product_type( $PRODUCTTYPE ),
                        #SUITEMASK   => $self->_suitemask( $SUITEMASK ),
                    },
    );

    my $build  = '';
       $build .= "build $OSVERSION{RAW}->{BUILD}" if $OSVERSION{RAW}->{BUILD};
    my $string = $OSVERSION{RAW}->{STRING};
    $OSVERSION{LONGNAME} = join ' ', $OSVERSION{NAME}, $string, $build;

    return;
}

sub _product_type {
    my $self = shift;
    my $pt   = shift || return;
    my %type = (
        1 => 'Workstation', # (NT 4, 2000 Pro, XP Home, XP Pro)
        2 => 'Domain Controller',
        3 => 'Server',
    );
    return $type{$pt}
}

1;

__END__

=head1 NAME

Sys::Info::Driver::Windows::OS - Windows backend for Sys::Info::OS

=head1 SYNOPSIS

This is a private sub-class.

=head1 DESCRIPTION

=head2 version

Version method returns the Windows version in C<%d.%d.%d> format. Possible
version values and corresponding names are:

   Version   Windows
   -------   -------
   0.0.0     Win32s
   1.4.0     Windows 95
   1.4.10    Windows 98
   1.4.90    Windows Me
   2.3.51    Windows NT 3.51
   2.4.0     Windows NT 4
   2.5.0     Windows 2000
   2.5.1     Windows XP
   2.5.2     Windows Server 2003
   2.6.0     Windows Vista

=head1 SEE ALSO

L<Win32>, L<Sys::Info>, L<Sys::Info::OS>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut

#------------------------------------------------------------------------------#

sub _suitemask {
   my $self = shift;
   my $mask = shift || return;
   # see http://msdn.microsoft.com/library/en-us/sysinfo/base/osversioninfoex_str.asp
   my %suitemask = (
   VER_SUITE_SMALLBUSINESS            => 0x00000001, # Microsoft Small Business Server was once installed on the system, but may have been upgraded to another version of Windows. Refer to the Remarks section for more information about this bit flag
   VER_SUITE_ENTERPRISE               => 0x00000002, # Windows Server 2003, Enterprise Edition, Windows 2000 Advanced Server, or Windows NT 4.0 Enterprise Edition, is installed. Refer to the Remarks section for more information about this bit flag
   VER_SUITE_BACKOFFICE               => 0x00000004, # Microsoft BackOffice components are installed
   VER_SUITE_COMMUNICATIONS           => 0x00000008, # ?
   VER_SUITE_TERMINAL                 => 0x00000010, # Terminal Services is installed
   VER_SUITE_SMALLBUSINESS_RESTRICTED => 0x00000020, # Microsoft Small Business Server is installed with the restrictive client license in force. Refer to the Remarks section for more information about this bit flag
   VER_SUITE_EMBEDDEDNT               => 0x00000040, # Windows XP Embedded is installed
   VER_SUITE_DATACENTER               => 0x00000080, # Windows Server 2003, Datacenter Edition or Windows 2000 Datacenter Server is installed
   VER_SUITE_SINGLEUSERTS             => 0x00000100, # Terminal Services is installed, but only one interactive session is supported
   VER_SUITE_PERSONAL                 => 0x00000200, # Windows XP Home Edition is installed
   VER_SUITE_BLADE                    => 0x00000400, # Windows Server 2003, Web Edition is installed
   VER_SUITE_EMBEDDED_RESTRICTED      => 0x00000800, # ?
   VER_SUITE_SECURITY_APPLIANCE       => 0x00001000, # ?
   );
   my @sm;
   foreach my $name (keys %suitemask) {
     push @sm, $name if $suitemask{$name} & $mask;
   }
   return [@sm] if @sm;
   return;
}

#JUNK

sub flag_info {
   my $self = shift;
   # see http://msdn.microsoft.com/library/en-us/sysinfo/base/osversioninfoex_str.asp
   return {
   VER_SUITE_SMALLBUSINESS            => 'Microsoft Small Business Server was once installed on the system, but may have been upgraded to another version of Windows',
   VER_SUITE_ENTERPRISE               => 'Windows Server 2003, Enterprise Edition, Windows 2000 Advanced Server, or Windows NT 4.0 Enterprise Edition, is installed',
   VER_SUITE_BACKOFFICE               => 'Microsoft BackOffice components are installed',
   VER_SUITE_COMMUNICATIONS           => '?',
   VER_SUITE_TERMINAL                 => 'Terminal Services is installed',
   VER_SUITE_SMALLBUSINESS_RESTRICTED => 'Microsoft Small Business Server is installed with the restrictive client license in force',
   VER_SUITE_EMBEDDEDNT               => 'Windows XP Embedded is installed',
   VER_SUITE_DATACENTER               => 'Windows Server 2003, Datacenter Edition or Windows 2000 Datacenter Server is installed',
   VER_SUITE_SINGLEUSERTS             => 'Terminal Services is installed, but only one interactive session is supported',
   VER_SUITE_PERSONAL                 => 'Windows XP Home Edition is installed',
   VER_SUITE_BLADE                    => 'Windows Server 2003, Web Edition is installed',
   VER_SUITE_EMBEDDED_RESTRICTED      => '?',
   VER_SUITE_SECURITY_APPLIANCE       => '?',
   };
}
