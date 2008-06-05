package Sys::Info::Driver::Unknown::OS;
use strict;
use vars qw( $VERSION );
use POSIX ();

$VERSION = '0.50';

use constant OS_SYSNAME  => 0;
use constant OS_NODENAME => 1;
use constant OS_RELEASE  => 2;
use constant OS_VERSION  => 3;
use constant OS_MACHINE  => 4;

use constant RE_BUILD => qr{\A Build \s+ (\d+) .* \z}xmsio;

# So, we don't support $^O yet, but we can try to emulate some features

BEGIN {
    *is_root = *uptime
             = *tick_count
             = *logon_server
             = sub { 0 }
             ;
    *domain_name = *edition = sub {};
}

sub meta {}
sub tz   {}

sub name      { (POSIX::uname)[OS_SYSNAME] }
sub long_name { join ' ', (POSIX::uname)[OS_SYSNAME, OS_RELEASE] }
sub version   { (POSIX::uname)[OS_RELEASE] }

sub build     {
    my $build = (POSIX::uname)[OS_VERSION] || return;
    if ( $build =~ RE_BUILD ) {
        return $1;
    }
    return $build;
}

sub fs { +() }

sub node_name { (POSIX::uname)[OS_NODENAME] }

sub login_name {
    my $name;
    eval { $name = getlogin() };
    return $name;
}

sub login_name_real { &login_name }

1;

__END__

=head1 NAME

Sys::Info::Driver::Unknown::OS - Compatibility layer for unsupported platforms

=head1 SYNOPSIS

Nothing public here.

=head1 DESCRIPTION

Nothing public here.

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
