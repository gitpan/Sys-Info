package Sys::Info::OS::Unknown;
use strict;
use vars qw[$VERSION];
use POSIX ();

use constant OS_SYSNAME  => 0;
use constant OS_NODENAME => 1;
use constant OS_RELEASE  => 2;
use constant OS_VERSION  => 3;
use constant OS_MACHINE  => 4;

# So, we don't support $^O yet, but we can try to emulate some features

BEGIN {
   *is_root = *uptime = *tick_count = sub {0};
}

$VERSION = '0.2';

sub name      { (POSIX::uname)[OS_SYSNAME] }
sub long_name { join ' ', (POSIX::uname)[OS_SYSNAME, OS_RELEASE] }
sub version   { (POSIX::uname)[OS_RELEASE] }
sub build     {
   my $build = (POSIX::uname)[OS_VERSION] || return;
   if($build =~ m{\A Build \s+ (\d+) .* \z}xmsio) {
      return $1;
   }
   return $build;
}

sub fs { +() }

sub node_name   { (POSIX::uname)[OS_NODENAME] }
sub domain_name {  }

sub login_name {
   my $name;
   eval { $name = getlogin() };
   return $name;
}

sub login_name_real { login_name }

1;

__END__

=head1 NAME

Sys::Info::OS::Unknown - Compatibility layer for unsupported platforms

=head1 SYNOPSIS

Nothing public here.

=head1 DESCRIPTION

Nothing public here.

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::OS>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
