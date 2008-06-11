package Sys::Info::Driver::Linux::OS;
use strict;
use vars qw( $VERSION );
# fstab entries
use constant FS_SPECIFIER     => 0;
use constant MOUNT_POINT      => 1;
use constant FS_TYPE          => 2;
use constant MOUNT_OPTS       => 3;
use constant DUMP_FREQ        => 4;
use constant FS_CHECK_ORDER   => 5;
# uname()
use constant SYSNAME          => 0;
use constant NODENAME         => 1;
use constant RELEASE          => 2;
use constant VERSION          => 3;
use constant MACHINE          => 4;
# getpwnam()
use constant REAL_NAME_FIELD  => 6;
use constant RE_LINUX_VERSION => qr{
   \A
   Linux\s+version\s
   (.+?)
   \s
   \(.+?\@.+?\)
   (.*?)
   \z
}xmsi;
use base qw( Sys::Info::Base );
use POSIX ();
use Cwd;
use Carp qw( croak );

$VERSION = '0.50';

my %OSVERSION; # cache
my %DISTROFIX = qw( suse SUSE );
my %PATH      = (
    fstab   => '/etc/fstab',    # for filesystem type of the current disk
    uptime  => '/proc/uptime',  # uptime file
    version => '/proc/version', # os version
    resolv  => '/etc/resolv.conf',
    #/etc/issue
);

sub edition {}

sub meta {
    my $self = shift;
    my $id   = shift;
    $self->_populate_osversion();
    my %info;
    $info{manufacturer}              = undef;
    $info{build_type}                = undef;
    $info{owner}                     = undef;
    $info{organization}              = undef;
    $info{product_id}                = undef;
    $info{install_date}              = $OSVERSION{RAW}->{BUILD_DATE};
    $info{boot_device}               = undef;
    $info{time_zone}                 = undef;
    $info{physical_memory_total}     = undef;
    $info{physical_memory_available} = undef;
    $info{page_file_total}           = undef;
    $info{page_file_available}       = undef;
    # windows specific
    $info{windows_dir}               = undef;
    $info{system_dir}                = undef;
    # ????
    $info{locale}                    = undef;

    $info{system_manufacturer}       = undef;
    $info{system_model}              = undef;
    $info{system_type}               = undef;
    $info{domain}                    = undef;

    $info{page_file_path}            = undef;

    return %info if ! $id;

    my $lcid = lc $id;
    if ( ! exists $info{ $lcid } ) {
        croak "$id meta value is not supported by the underlying Operating System";
    }
    return $info{ $lcid };
}

sub tz           {}
sub logon_server {}

sub tick_count {
    my $self = shift;
    my $uptime = $self->slurp($PATH{uptime}) || return 0;
    my @uptime = split /\s+/, $uptime;
    # this file has two entries. uptime is the first one. second: idle time
    return $uptime[0];
}

sub name {
    my $self = shift;
    my %opt  = @_ % 2 ? () : (@_);
    $self->_populate_osversion();
    my $id   = $opt{long} ? 'LONGNAME' : 'NAME';
    return $OSVERSION{ $id };
}

sub version   { shift->_populate_osversion(); return $OSVERSION{VERSION}      }
sub build     { shift->_populate_osversion(); return $OSVERSION{RAW}->{BUILD} }
sub uptime    {                               return time - shift->tick_count }

# user methods
sub is_root {
    return 0 if defined &Sys::Info::EMULATE;
    my $name = login_name();
    my $id   = POSIX::geteuid();
    my $gid  = POSIX::getegid();
    return 0 if $@;
    return 0 if ! defined($id) || ! defined($gid);
    return $id == 0 && $gid == 0 && $name eq 'root';
}

sub login_name {
    my $self  = shift;
    my %opt   = @_ % 2 ? () : (@_);
    my $login = POSIX::getlogin();
    return $opt{real} ? (getpwnam $login)[REAL_NAME_FIELD] : $login;
}

sub node_name { (POSIX::uname())[NODENAME] }

sub domain_name {
    my $self = shift;
    my $domain;
    # hmmmm...
    foreach my $line ( $self->read_file( $PATH{resolv} ) ) {
        chomp $line;
        if ( $line =~ m{\A domain \s+ (.*) \z}xmso ) {
            $domain = $1;
            last;
        }
    }
    return $domain;
}

sub fs {
    my $self = shift;
    $self->{current_dir} = Cwd::getcwd();

    my(@fstab, @junk, $re);
    foreach my $line( $self->read_file($PATH{fstab}) ) {
        chomp $line;
        next if $line =~ m[^#];
        @junk = split /\s+/, $line;
        next if ! @junk || @junk != 6;
        next if lc($junk[FS_TYPE]) eq 'swap'; # ignore swaps
        $re = $junk[MOUNT_POINT];
        next if $self->{current_dir} !~ m{\Q$re\E}i;
        push @fstab, [ $re, $junk[FS_TYPE] ];
    }

    @fstab  = sort( { $b->[0] cmp $a->[0] } @fstab ) if @fstab > 1;
    my $fstype = $fstab[0]->[1];
    my $attr   = $self->_fs_attributes( $fstype );
    return(
        filesystem => $fstype,
        ($attr ? %{$attr} : ())
    );
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _ip {
    my $self = shift;
    my $raw  = qx(ifconfig);
    return if not $raw;
    my @raw = split /inet addr/, $raw;
    if ( $raw[1] =~ m{(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})}xmso ) {
        return $1;
    }
    return;
}

sub _populate_osversion {
    return if %OSVERSION;
    my $self    = shift;
    my $version = '';

    if (  -e $PATH{'version'} && -f _) {
        $version =  $self->trim(
                        $self->slurp(
                            $PATH{'version'},
                            'I can not open linux version file %s for reading: '
                        )
                    );
    }

    my($str, $build_date) = split /\#/, $version;
    my($kernel, $distro)  = ('','');
    #$build_date = "1 Fri Jul 23 20:48:29 CDT 2004';";
    #$build_date = "1 SMP Mon Aug 16 09:25:06 EDT 2004";
    $build_date = '' if not $build_date; # running since blah thingie
    # format: 'Linux version 1.2.3 (foo@bar.com)'
    # format: 'Linux version 1.2.3 (foo@bar.com) (gcc 1.2.3)'
    # format: 'Linux version 1.2.3 (foo@bar.com) (gcc 1.2.3 (Redhat blah blah))'
    if ( $str =~ RE_LINUX_VERSION ) {
        $kernel = $1;
        if ( $distro = $self->trim( $2 ) ) {
            if ( $distro =~ m{ \s\((.+?)\)\) \z }xms ) {
                $distro = $1;
            }
        }
    }

    $distro = 'Linux' if not $distro or $distro =~ m{\(gcc};

    # kernel build date
    $build_date = $self->date2time($build_date) if $build_date;
    my $build = $build_date ? $self->date2time($build_date) : '';
    $build = scalar( localtime $build ) if $build;

    require Linux::Distribution;
    my $linux = Linux::Distribution->new;
    my($dn, $dv);
    if ( $dn = $linux->distribution_name ) {
        $dn  = $DISTROFIX{$dn} || ucfirst $dn;
        $dn .= ' Linux';
        $dv  = $linux->distribution_version;
    }

    %OSVERSION = (
        NAME     => $dn || $distro,
        LONGNAME => undef,
        VERSION  => $dv || $kernel,
        KERNEL   => $kernel,
        RAW      => {
                        BUILD      => defined $build      ? $build      : 0,
                        BUILD_DATE => defined $build_date ? $build_date : 0,
                    },
    );

    $OSVERSION{LONGNAME} = sprintf "%s %s (kernel: %s)",
                                   $OSVERSION{NAME},
                                   $OSVERSION{VERSION},
                                   $kernel;
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

Sys::Info::Driver::Linux::OS - Linux backend

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

Copyright 2006-2008 Burak Gürsoy. All rights reserved.

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


