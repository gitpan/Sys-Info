package Sys::Info::OS::Windows;
use strict;
use vars qw[$VERSION];
use Win32;
use constant USER_INFO_LEVEL => 3;

$VERSION = '0.3';

my %OSVERSION;  # see _POPULATE_OSVERSION
my %FILESYSTEM; # see _POPULATE_FS

BEGIN {
   *is_win95 = sub{Win32::IsWin95()};
   *is_winnt = sub{Win32::IsWinNT()};
   # Win32::IsAdminUser(): Perl 5.8.3 Build 809 Monday, Feb 2, 2004
   my $IS_ROOT = defined &Win32::IsAdminUser ? Win32::IsAdminUser()
               : is_win95()                  ? 1
               :                               0
               ;
   *is_root  = sub{ $IS_ROOT };
   *is_win9x = *is_win95;
}

sub name        { _POPULATE_OSVERSION(); return $OSVERSION{NAME}              }
sub long_name   { _POPULATE_OSVERSION(); return $OSVERSION{LONGNAME}          }
sub version     { _POPULATE_OSVERSION(); return $OSVERSION{VERSION}           }
sub build       { _POPULATE_OSVERSION(); return $OSVERSION{RAW}->{BUILD} || 0 }
sub uptime      {                        return time - shift->tick_count      }
sub node_name   { Win32::NodeName()                     }
sub domain_name { is_win95() ? '' : Win32::DomainName() }

sub tick_count {
   my $tick = Win32::GetTickCount() || return 0;
   return $tick / 1000; # in miliseconds
}

sub login_name { Win32::LoginName() }

sub login_name_real {
   my $name = login_name() || return '';
   my $real = _fnfrom_win32apinet($name);
   return $real || $name;
}

sub fs {
   _POPULATE_FS();
   my $self = shift;
   return %FILESYSTEM;
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _fnfrom_win32apinet {
   # Win32API::Net: 0.13  Thu Sep 17 19:35:20 1998
   # Some changes : 0.15  Sat Sep 25 15:53:02 1999
   # seems OK ot use.
   return if is_win95(); # workaround???
   eval { require Win32API::Net; };
   if($@) {
      warn "Win32API::Net can not be loaded: $@";
      return;
   }
   my $user   = shift || return;
   my $server = node_name();
   my %info;
   Win32API::Net::UserGetInfo($server, $user, USER_INFO_LEVEL, \%info);
   return $info{fullName};
   # $info{comment}
}

sub _POPULATE_FS {
   return if %FILESYSTEM;
   my($FSTYPE, $FLAGS, $MAXCOMPLEN) = Win32::FsType();
   if (!$FSTYPE && Win32::GetLastError()) {
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
      foreach (keys %flag) {
         push @fl, $_ => $flag{$_} & $FLAGS ? 1 : 0;
      }
   }
   push @fl, max_file_length => $MAXCOMPLEN if $MAXCOMPLEN;
   push @fl, filesystem      => $FSTYPE     if $FSTYPE; # NTFS/FAT/FAT32
   %FILESYSTEM = (@fl);
   return;
}

sub _POPULATE_OSVERSION {
   return if %OSVERSION;
   # Win32::GetOSName() is not reliable.
   # Since, an older release will not have any idea about XP or Vista
   my(
      $STRING , $MAJOR  , $MINOR    , $BUILD      , $ID, # All
      $SPMAJOR, $SPMINOR, $SUITEMASK, $PRODUCTTYPE       # NT 4 SP6 and later
      ) = Win32::GetOSVersion();
   my $t = sub { $MAJOR == $_[0] && $MINOR == $_[1] };
   my $j = join '.', $ID, $MAJOR || '', $MINOR || '';
   my $os;

      if($ID == 0) {      $os = 'Win32s'              }
   elsif($ID == 1) {
         if($t->(4,  0)) {$os = 'Windows 95'          }
      elsif($t->(4, 10)) {$os = 'Windows 98'          }
      elsif($t->(4, 90)) {$os = 'Windows Me'          }
      else               {$os = "Windows 9x $j"       }
   }
   elsif($ID == 2) {
         if($t->(3, 51)) {$os = 'Windows NT 3.51'     }
      elsif($t->(4,  0)) {$os = 'Windows NT 4'        }
      elsif($t->(5,  0)) {$os = 'Windows 2000'        }
      elsif($t->(5,  1)) {$os = 'Windows XP'          }
      elsif($t->(5,  2)) {$os = 'Windows Server 2003' }
      elsif($t->(6,  0)) {$os = 'Windows Vista'       }
      else               {$os = "Windows NT $j"       }
   }
   else                  {$os = "Windows $j"          }

   %OSVERSION = (
      NAME     => $os,
      LONGNAME => '',
      VERSION  => join('.', $ID, $MAJOR || 0, $MINOR || 0),
      RAW      => {
                     STRING      => $STRING,
                     MAJOR       => $MAJOR,
                     MINOR       => $MINOR,
                     BUILD       => $BUILD,
                     ID          => $ID,
                     SPMAJOR     => $SPMAJOR,
                     SPMINOR     => $SPMINOR,
                     #SUITEMASK   => __PACKAGE__->_GET_SUITEMASK($SUITEMASK),
                     #PRODUCTTYPE => __PACKAGE__->_GET_PRODUCT_TYPE($PRODUCTTYPE),
      },
   );
   my $build  = $OSVERSION{RAW}->{BUILD} ? "build $OSVERSION{RAW}->{BUILD}" : '';
   my $string = $OSVERSION{RAW}->{STRING};
   $OSVERSION{LONGNAME} = join ' ', $OSVERSION{NAME}, $string, $build;
   return;
}

1;

__END__

=head1 NAME

Sys::Info::OS::Windows - Windows backend for Sys::Info::OS

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

Copyright 2006 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut

#------------------------------------------------------------------------------#

sub _GET_PRODUCT_TYPE {
   my $self = shift;
   my $pt   = shift || return;
   my %type = (
      1 => 'Workstation', # (NT 4, 2000 Pro, XP Home, XP Pro)
      2 => 'Domain Controller',
      3 => 'Server',
   );
   return $type{$pt}
}

sub _GET_SUITEMASK {
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
