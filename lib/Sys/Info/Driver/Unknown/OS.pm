package Sys::Info::Driver::Unknown::OS;
use strict;
use vars qw( $VERSION );
use POSIX ();
use Sys::Info::Constants qw( :unknown );

$VERSION = '0.60';

# So, we don't support $^O yet, but we can try to emulate some features

BEGIN {
    *is_root     = *uptime
                 = *tick_count
                 = sub { 0 }
                 ;
    *domain_name = *edition
                 = *logon_server
                 = sub {   }
                 ;
}

sub meta {
    my $self = shift;
    my %info;

    $info{manufacturer}              = undef;
    $info{build_type}                = undef;
    $info{owner}                     = undef;
    $info{organization}              = undef;
    $info{product_id}                = undef;
    $info{install_date}              = undef;
    $info{boot_device}               = undef;
    $info{physical_memory_total}     = undef;
    $info{physical_memory_available} = undef;
    $info{page_file_total}           = undef;
    $info{page_file_available}       = undef;
    # windows specific
    $info{windows_dir}               = undef;
    $info{system_dir}                = undef;
    $info{system_manufacturer}       = undef;
    $info{system_model}              = undef;
    $info{system_type}               = undef;
    $info{page_file_path}            = undef;

    return %info;
}

sub tz {
    my $self = shift;
    return exists $ENV{TZ} ? $ENV{TZ} : undef;
}

sub fs { +() }

sub name {
    my $self  = shift;
    my %opt   = @_ % 2 ? () : (@_);
    my @uname = POSIX::uname();
    my $rv    = $opt{long} ? join(' ', @uname[UN_OS_SYSNAME, UN_OS_RELEASE])
              :              $uname[UN_OS_SYSNAME]
              ;
    return $rv;
}

sub version { (POSIX::uname)[UN_OS_RELEASE] }

sub build {
    my $build = (POSIX::uname)[UN_OS_VERSION] || return;
    if ( $build =~ UN_RE_BUILD ) {
        return $1;
    }
    return $build;
}

sub node_name { (POSIX::uname)[UN_OS_NODENAME] }

sub login_name {
    my $name;
    eval { $name = getlogin() };
    return $name;
}

1;

__END__

=head1 NAME

Sys::Info::Driver::Unknown::OS - Compatibility layer for unsupported platforms

=head1 SYNOPSIS

-

=head1 DESCRIPTION

-

=head1 METHODS

Please see L<Sys::Info::OS> for definitions of these methods and more.

=head2 build

=head2 domain_name

=head2 edition

=head2 fs

=head2 is_root

=head2 login_name

=head2 logon_server

=head2 meta

=head2 name

=head2 node_name

=head2 tick_count

=head2 tz

=head2 uptime

=head2 version

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::OS>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
