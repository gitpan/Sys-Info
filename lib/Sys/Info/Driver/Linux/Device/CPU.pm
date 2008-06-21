package Sys::Info::Driver::Linux::Device::CPU;
use strict;
use vars qw($VERSION);
use base qw(Sys::Info::Base);
use Sys::Info::Driver::Linux;

$VERSION = '0.50';

sub identify {
    my $self = shift;
    return $self->_serve_from_cache(wantarray) if $self->{CACHE};

    my @cpu;
    foreach my $e ( split /\n\n/, $self->trim( proc->{cpuinfo} ) ) {
        push @cpu, { $self->_parse_cpuinfo($e) };
    }
    $self->{CACHE} = [@cpu];

    return $self->_serve_from_cache(wantarray);
}

sub load {
    my $self   = shift;
    my $level  = shift;
    my @loads  = split /\s+/, $self->slurp( proc->{loadavg} );
    return $loads[$level];
}

sub _parse_cpuinfo {
    my $self = shift;
    my $raw  = shift || die "Parser called without data";
    my($k, $v);
    my %cpu;
    foreach my $line (split /\n/, $raw) {
        ($k, $v) = split /\s+:\s+/, $line;
        $cpu{$k} = $v;
    }

    my @flags = split /\s+/, $cpu{flags};
    my %flags = map { $_ => 1 } @flags;

    return(
        data_width    => $flags{lm} ? 64 : 32, # guess
        address_width => $flags{lm} ? 64 : 32, # guess
        bus_speed     => undef,
        speed         => $cpu{'cpu MHz'},
        name          => $cpu{'model name'},
        family        => $cpu{'cpu family'},
        manufacturer  => $cpu{vendor_id},
        model         => $cpu{model},
        stepping      => $cpu{stepping},
        L1_cache      => {
            max_cache_size => $cpu{'cache size'},
        },
        ( @flags ? (
        flags => [ @flags ],
        ) : ()),
    );
}

1;

__END__
