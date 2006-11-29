package Sys::Info::OS::Linux;
use strict;
use vars qw[$VERSION];
# fstab entries
use constant FS_SPECIFIER    => 0;
use constant MOUNT_POINT     => 1;
use constant FS_TYPE         => 2;
use constant MOUNT_OPTS      => 3;
use constant DUMP_FREQ       => 4;
use constant FS_CHECK_ORDER  => 5;
#--------------------------------------------#
# uname()
use constant SYSNAME  => 0;
use constant NODENAME => 1;
use constant RELEASE  => 2;
use constant VERSION  => 3;
use constant MACHINE  => 4;
#--------------------------------------------#
use constant REAL_NAME_FIELD => 6;
use base qw(Sys::Info::Util);
use POSIX ();
use Cwd;

$VERSION = '0.2';

my %OSVERSION;
my %DISTROFIX = qw(suse SuSE);
my %PATH      = (
   fstab   => '/etc/fstab',    # for filesystem type of the current disk
   uptime  => '/proc/uptime',  # uptime file
   version => '/proc/version', # os version
   resolv  => '/etc/resolv.conf',
   #/etc/issue
);

sub tick_count {
   my $self = shift;
   # this file has two entries. uptime is the first one
   my $uptime = $self->slurp($PATH{uptime}) || return 0;
   my @uptime = split /\s+/, $uptime;
   return $uptime[0];
}

sub name      { shift->_POPULATE_OSVERSION(); return $OSVERSION{NAME}              }
sub long_name { shift->_POPULATE_OSVERSION(); return $OSVERSION{LONGNAME}          }
sub version   { shift->_POPULATE_OSVERSION(); return $OSVERSION{VERSION}           }
sub build     { shift->_POPULATE_OSVERSION(); return $OSVERSION{RAW}->{BUILD} || 0 }
sub uptime    {                               return time - shift->tick_count      }

# user methods
sub is_root {
   return 0 if defined &Sys::Info::EMULATE;
   my $name = login_name();
   my $id   = POSIX::geteuid();
   my $gid  = POSIX::getegid();
   return 0 if $@;
   return 0 unless defined($id) && defined($gid);
   return $id == 0 && $gid == 0 && $name eq 'root';
}

sub login_name {
   return '' if defined &Sys::Info::EMULATE;
   return POSIX::getlogin();
}

sub login_name_real {
   my $name = login_name() || return '';
   my $real = (getpwnam $name)[REAL_NAME_FIELD];
   return $real || $name;
}

sub node_name { (POSIX::uname())[NODENAME] }

sub domain_name {
   my $self = shift;
   my $domain;
   # hmmmm...
   foreach my $line ( $self->read_file( $PATH{resolv} ) ) {
      chomp $line;
      if($line =~ m{\A domain \s+ (.*) \z}xmso) {
         $domain = $1;
         last;
      }
   }
   return $domain;
}

sub fs {
   my $self = shift;
      $self->{current_dir} = Cwd::getcwd();
   #   $self->{current_dir} = '/home/burak/public_html';
   my @file = $self->read_file($PATH{fstab});
   my(@fstab, @junk, $re);
   foreach my $line(@file) {
      chomp $line;
      next if $line =~ m[^#];
      @junk = split /\s+/, $line;
      next unless @junk && @junk == 6;
      next if lc($junk[FS_TYPE]) eq 'swap'; # ignore swaps
      $re = $junk[MOUNT_POINT];
      next unless $self->{current_dir} =~ m,$re,i;
      push @fstab, [$re, $junk[FS_TYPE]];
   }
      @fstab  = sort({$b->[0] cmp $a->[0]} @fstab) if scalar(@fstab) > 1;
   my $fstype = $fstab[0]->[1];
   my $attr   = $self->_fs_attributes($fstype);
   return
      filesystem => $fstype,
      ($attr ? %{$attr} : ())
   ;
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _ip {
   my $self = shift;
   my $raw  = qx(ifconfig);
   return if not $raw;
   my @raw = split /inet addr/, $raw;
   if ($raw[1] =~ m{(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})}xmso) {
      return $1;
   }
}

sub _POPULATE_OSVERSION {
   return if %OSVERSION;
   my $self    = shift;
   my $version = '';
   if (-e $PATH{'version'} and -f _) {
      $version = $self->slurp($PATH{'version'}, 'I can not open linux version file %s for reading: ');
   }
   $version =~ s[\s+$][]s;
   my($kernel, $distro) = ('','');
   my($str, $build_date)   = split /\#/, $version;
   #$build_date = "1 Fri Jul 23 20:48:29 CDT 2004';";
   #$build_date = "1 SMP Mon Aug 16 09:25:06 EDT 2004";
   $build_date = '' unless $build_date; # running since blah thingie
   # format: 'Linux version 1.2.3 (foo@bar.com)'
   # format: 'Linux version 1.2.3 (foo@bar.com) (gcc 1.2.3)'
   # format: 'Linux version 1.2.3 (foo@bar.com) (gcc 1.2.3 (Redhat blah blah))'
   if ($str =~  m[^Linux version\s(.+?)\s\(.+?\@.+?\)(.*?)$]i) {
      $kernel = $1;
      if($distro = $2) {
         $distro =~ s[\s+$][];
         $distro =~ s[^\s][];
         if ($distro =~ m{\s\((.+?)\)\)$}) {
            $distro = $1;
         }
      }
   }

   $distro = 'Linux' if not $distro or $distro =~ m[\(gcc];

   my $build = $build_date ? $self->date2time($build_date) : '';  # kernel build date
   $build = scalar localtime $build if $build;

   require Linux::Distribution;
   my $linux = Linux::Distribution->new;
   my($dn, $dv);
   if($dn = $linux->distribution_name) {
      $dn  = $DISTROFIX{$dn} || ucfirst $dn;
      $dn .= ' Linux';
      $dv  = $linux->distribution_version;
   }

   %OSVERSION = (
      NAME     => $dn || $distro,
      LONGNAME => undef,
      VERSION  => $dv || $kernel,
      KERNEL   => $kernel,
      RAW      => {BUILD => $build },
   );
   #$OSVERSION{LONGNAME} = "$distro (kernel: $kernel)";
   $OSVERSION{LONGNAME} = "$OSVERSION{NAME} $OSVERSION{VERSION} (kernel: $kernel)";
   return;
}

sub _fs_attributes {
   my $self = shift;
   my $fs   = shift;
   my $_PC_PATH_MAX;

   return {
      ext3 => {
               case_sensitive     => 1, #'supports case-sensitive filenames',
               preserve_case      => 1, #'preserves the case of filenames',
               unicode            => 1, #'supports Unicode in filenames',
               #acl                => '', #'preserves and enforces ACLs',
               #file_compression   => '', #'supports file-based compression',
               #disk_quotas        => '', #'supports disk quotas',
               #sparse             => '', #'supports sparse files',
               #reparse            => '', #'supports reparse points',
               #remote_storage     => '', #'supports remote storage',
               #compressed_volume  => '', #'is a compressed volume (e.g. DoubleSpace)',
               #object_identifiers => '', #'supports object identifiers',
               efs                => '1', #'supports the Encrypted File System (EFS)',
               #max_file_length    => '';
      },
   }->{$fs};
}

# Sys::Info::EMULATE
#    I'm emulating linux environment on windows to test module
#    interface. If this sub is defined, some methods will return false

1;

__END__

=head1 NAME

Sys::Info::OS::Linux - Linux backend for Sys::Info::OS

=head1 SYNOPSIS

Nothing public here.

=head1 DESCRIPTION

Nothing public here.

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::OS>,
The C</proc> virtual filesystem:
L<http://www.redhat.com/docs/manuals/linux/RHL-9-Manual/ref-guide/s1-proc-topfiles.html>.

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



sub _fetch_user_info {
   my %user;
   $user{NAME}               = POSIX::getlogin();
   $user{REAL_USER_ID}       = POSIX::getuid();  # $< uid
   $user{EFFECTIVE_USER_ID}  = POSIX::geteuid(); # $> effective uid
   $user{REAL_GROUP_ID}      = POSIX::getgid();  # $( guid
   $user{EFFECTIVE_GROUP_ID} = POSIX::getegid(); # $) effective guid
   my %junk;
   # quota, comment & expire are unreliable
   @junk{qw(name  passwd  uid  gid
            quota comment gcos dir shell expire)} = getpwnam($user{NAME});
   $user{REAL_NAME} = defined $junk{gcos}    ? $junk{gcos}    : '';
   $user{COMMENT}   = defined $junk{comment} ? $junk{comment} : '';
   return %user;
}


