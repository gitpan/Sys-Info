package Sys::Info::CPU::Windows::WMI;
use strict;
use vars qw[$VERSION];
use Win32::OLE qw (in);

$VERSION = '0.5';

my $CACHE;
my %RENAME = qw(
   DataWidth           data_width
   CurrentClockSpeed   speed
   ExtClock            bus_speed
   AddressWidth        address_width
   Name                name
);

sub wmi_cpu {
   my $self     = shift;
   my $is_cache = $self->{cache};
   my $ctimeout = $self->{cache_timeout} || $self->DEFAULT_TIMEOUT; # in seconds
   if ($is_cache && $CACHE) {
      if ($CACHE->{TIMESTAMP} + $ctimeout < time) {
         %{ $CACHE } = ();
      } else {
         return @{ $CACHE->{DATA} };
      }
   }
   my(%attr, @attr, $val, $cpu, $name);
   foreach $cpu (in __PACKAGE__->_GET_WMI_CPU_OBJECT) {
      foreach $name (keys %RENAME) {
         $val = $cpu->$name();
         next if not defined $val;
         $val =~ s{\A \s+}{}ms if $name eq 'Name';
         $attr{ $RENAME{$name} } = $val;
      }
      # LoadPercentage : undef dönüyor
      $attr{LoadPercentage} = sprintf('%.2f', $attr{LoadPercentage} / 100) if $attr{LoadPercentage};
      push @attr, {%attr};
      %attr = (); # reset
   }
   $CACHE = { TIMESTAMP => time, DATA => [@attr] } if $is_cache; 
   return @attr;
}

sub _GET_WMI_OBJECT {
   my $WMI = Win32::OLE->GetObject("WinMgmts:") || return; 
   die Win32::OLE->LastError() if Win32::OLE->LastError() != 0;
   return $WMI;
}

sub _GET_WMI_CPU_OBJECT {
   my $WMI    = __PACKAGE__->_GET_WMI_OBJECT() || return; 
   my $CPUset = $WMI->InstancesOf("Win32_Processor") || return;
   die Win32::OLE->LastError() if Win32::OLE->LastError() != 0;
   return $CPUset;
}

1;

__END__

=head1 NAME

Sys::Info::CPU::Windows::WMI - Fetch CPU metadata through WMI

=head1 SYNOPSIS

Nothing public here.

=head1 DESCRIPTION

WMI plugin for C<Sys::Info::CPU::Windows>.

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::CPU>,
L<http://vbnet.mvps.org/index.html?code/wmi/win32_processor.htm>

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut

use constant WMI_CPU_METHODS => qw(
   Caption
   Description
   Manufacturer
   Version

   SocketDesignation
   DeviceID
   Status

   MaxClockSpeed
);
use constant WMI_CPU_METHODS2 => qw(
   Availability
   CpuStatus
   CurrentVoltage
   Family
   Level
   ProcessorType
   Revision
   StatusInfo
   Stepping
   UpgradeMethod

   PowerManagementSupported
   ProcessorId
);
