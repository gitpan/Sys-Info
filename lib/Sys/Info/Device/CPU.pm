package Sys::Info::Device::CPU;
use strict;
use vars qw( $VERSION @ISA );
use constant DEFAULT_TIMEOUT => 10;
use Sys::Info qw(OSID);
use Carp qw( croak );
use base qw( Sys::Info::Base );

$VERSION = '0.50';

BEGIN {
    push @ISA, __PACKAGE__->load_subclass('Sys::Info::Driver::%s::Device::CPU');
}

sub new {
    my $class = shift;
    my %opt   = scalar(@_) % 2 ? () : (@_);
    my $self  = {
        %opt,
        CACHE => undef,
    };
    bless $self, $class;
    $self;
}

sub count {
    my $self = shift;
    $self->identify if not $self->{CACHE};
    my @cpu = @{ $self->{CACHE} };
    return if not @cpu;
    return scalar @cpu;
}

sub ht { &hyper_threading }

sub hyper_threading {
    my $self = shift;
    $self->identify if not $self->{CACHE};
    my %test;
    my $logical = 0;

    foreach my $cpu ( @{ $self->{CACHE} } ) {
        $logical++;
        my $wmi_cores   = $cpu->{NumberOfCores};
        my $wmi_logical = $cpu->{NumberOfLogicalProcessors};
        if ( defined $wmi_cores && defined $wmi_logical ) {
            return $wmi_cores != $wmi_logical;
        }
        next if not exists $cpu->{socket_designation};
        $test{ $cpu->{socket_designation} }++;
    }

    return 0 if $logical < 1;  # failed to fill cache
    my $physical = keys %test;
    return 0 if $physical < 1; # an error occurred somehow
    return $logical > $physical ? 1 : 0;
}

sub speed {
    my $self = shift;
    $self->identify if not $self->{CACHE};
    my @cpu = @{ $self->{CACHE} };
    return if !@cpu || !ref($cpu[0]);
    return $cpu[0]->{speed};
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _serve_from_cache {
    my $self    = shift;
    my $context = shift;
    croak "Can not happen: cache is not set" if not $self->{CACHE};
    return if not defined $context; # void context
    if ( not $context ) { # scalar context
        # OK for single processor ("name" will be same)
        my $count = $self->count;
        $count = undef if $count && $count == 1; # "1 x CPU" is meaningless
        my $name  = $self->{CACHE}[0] ? $self->{CACHE}[0]{name} : '';
        return $name if not $count;
        return "$count x $name";
    }
    return @{ $self->{CACHE} };
}

1;

__END__

=head1 NAME

Sys::Info::Device::CPU - CPU information.

=head1 SYNOPSIS

   use Sys::Info;
   my $info = Sys::Info->new;
   my $cpu  = $info->device( CPU => %options );

Example:

   printf "CPU: %s\n", scalar($cpu->identify)  || 'N/A';
   printf "CPU speed is %s MHz\n", $cpu->speed || 'N/A';
   printf "There are %d CPUs\n"  , $cpu->count || 1;
   printf "CPU load: %s\n"       , $cpu->load  || 0;

=head1 DESCRIPTION

Collects and returns information about the Central Processing Unit
(CPU) on the host machine.

Some platforms can limit the available information under some
user accounts and this will affect the accessible amount of
data. When this happens, some methods will not return
anything usable.

=head1 METHODS

=head2 new

Acceps parameters in C<< key => value >> format.

=head3 cache

If has a true value, internal cache will be enabled.
Cache timeout can be controlled via C<cache_timeout>
parameter.

On some platforms, some methods can take a long time
to be completed (i.e.: WMI access on Windows platform).
If cache is enabled, all gathered data will be saved
in an internal in-memory cache and, the related method will
serve from cache until the cache expires.

Cache only has a meaning, if you call the related method
continiously (in a loop, under persistent environments
like GUI, mod_perl, PerlEx, etc.). It will not have any
effect if you are calling it only once.

=head3 cache_timeout

Must be used together with C<cache> parameter. If cache
is enabled, and this is not set, it will take the default
value: C<10>.

Timeout value is in seconds.

=head3 disable_si

If has a true value, I<slow interfaces> like I<Windows WMI>
will be disabled. Such interfaces I<may> be slow, but
returns more detailed information. Infact, if you set this
option to a true value, you'll probably get nothing useful.

=head2 identify

If called in a list context; returns an AoH filled with
CPU metadata. If called in a scalar context, returns the
name of the CPU (if CPU is multi-core or there are multiple CPUs,
it'll also include the number of CPUs).

Returns C<undef> upon failure.

=head2 speed

Returns the CPU clock speed in MHz if successful.
Returns C<undef> otherwise.

=head2 count

Returns the number of CPUs (or number of total cores).

=head2 load [, LEVEL]

Returns the CPU load percentage if successful.
Returns C<undef> otherwise.

The average CPU load average in the last minute. If you pass a 
level argument, it'll return the related CPU load.

    LEVEL   MEANING
    -----   -------------------------------
        0   CPU Load in the last  1 minute
        1   CPU Load in the last  5 minutes
        2   CPU Load in the last 10 minutes

C<LEVEL> defaults to C<0>.

Using this method under I<Windows> is not recommended since,
the C<WMI> interface will possibly take at least C<2> seconds
to complete the request.

=head2 hyper_threading

=head2 ht

Returns true if hyper threading is supported.

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::OS>.

=head1 AUTHOR

Burak G�rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Burak G�rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
