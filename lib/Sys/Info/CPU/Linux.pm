package Sys::Info::CPU::Linux;
use strict;
use vars qw[$VERSION];
use base qw(Sys::Info::Util);

$VERSION = '0.4';

my %PATH = (
   loadavg => '/proc/loadavg', # average cpu load
   cpu     => '/proc/cpuinfo',
);

sub identify {
   my $self = shift;
   return unless defined wantarray;
   return $self->_serve_from_cache(wantarray) if $self->{CACHE};

   my $raw = $self->slurp($PATH{cpu});
      $raw =~ s{\A \s+}{}xms;
      $raw =~ s{\s+ \z}{}xms;
   my @raw = split /\n\n/, $raw;
   my @cpu;
   foreach my $e (@raw) {
      push @cpu, { $self->_parse($e) };
   }
   $self->{CACHE} = [@cpu];

   return $self->_serve_from_cache(wantarray);
}

sub load {
   my $self   = shift;
   my $level  = shift || 0;
      $level += 0;
   die "Illegal cpu_load level: $level" if $level < 0 || $level > 2;
   my @loads = split /\s+/, $self->slurp($PATH{loadavg});
   return $loads[$level];
}

sub _parse {
   my $self = shift;
   my $raw  = shift || die "Parser called without data";
   my($k, $v);
   my %cpu;
   foreach my $line (split /\n/, $raw) {
      ($k, $v) = split /\s+:\s+/, $line;
      $cpu{$k} = $v;
   }
   #$cpu{'cache size'} $cpu{'bogomips'}
   return(
      data_width    => undef,
      address_width => undef,
      bus_speed     => undef,
      speed         => $cpu{'cpu MHz'},
      name          => $cpu{'model name'},
   );
}

1;

__END__

=head1 NAME

Sys::Info::CPU::Linux - Linux driver for Sys::Info::CPU

=head1 SYNOPSIS

Nothing public here.

=head1 DESCRIPTION

Nothing public here.

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::CPU>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
