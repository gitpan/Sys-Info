package Sys::Info::Util;
use strict;
use vars qw[$VERSION];
use IO::File;

$VERSION = '0.1';

sub slurp { # fetches all data inside a flat file
   my $self   = shift;
   my $file   = shift;
   my $msgerr = shift || 'I can not open file %s for reading: ';
   my $FH     = IO::File->new;
   $FH->open($file) or die sprintf($msgerr, $file).$!;
   local $/;
   my $slurped;
   chomp($slurped = <$FH>);
   close  $FH;
   return $slurped;
}

sub read_file {
   my $self   = shift;
   my $file   = shift;
   my $msgerr = shift || 'I can not open file %s for reading: ';
   my $FH     = IO::File->new;
   $FH->open($file) or die sprintf($msgerr, $file).$!;
   my @flat   = <$FH>;
   close  $FH;
   return @flat;
}

sub date2time { # date stamp to unix time stamp conversion
   my $self  = shift;
   my $stamp = shift || die "No date input specified!";

   my($c, $d) = (0,0); # index counter
   my %wdays  = map{ $_ => $c++} qw(Sun Mon Tue Wed Thu Fri Sat);
   my %months = map{ $_ => $d++} qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
   my @junk   = split /\s+/, $stamp;
   my $reg    = join '|', keys %wdays;
   # remove until ve get a day name
   while($junk[0] !~ m[^($reg)$]i) {
      shift @junk;
      last unless @junk;
   }
   return '' unless @junk;
   my($wday, $month, $date, $time, $zone, $year) = @junk;
   $wday  = $wdays{$wday};
   $month = $months{$month};
   my($hour, $min, $sec) = split (/\:/, $time);
   $year -= 1900;
   require POSIX;
   my $timestamp = POSIX::mktime($sec, $min, $hour, $date, $month, $year, $wday, 0, -1);
   return $timestamp;
}

1;

__END__

=head1 NAME

Sys::Info::Util - Utility methods for Sys::Info.

=head1 SYNOPSIS

Used internally. Nothing public here.

=head1 DESCRIPTION

This module is used internally by several sub-modules.
Not a public module.

=head1 SEE ALSO

L<Sys::Info>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
