package Sys::Info::Driver::Windows::Device::CPU;
use strict;
use vars     qw( $VERSION @ISA $Registry );
use constant HW_KEY  => 'HKEY_LOCAL_MACHINE/HARDWARE/';
use constant CPU_KEY => HW_KEY.'DESCRIPTION/System/CentralProcessor';
use base qw(
    Sys::Info::Driver::Unknown::Device::CPU::Env
    Sys::Info::Driver::Windows::Device::CPU::WMI
);

$VERSION = '0.50';

my $REG;
TRY_TO_LOAD: {
    # SetDualVar req. in Win32::TieRegistry breaks any handler
    local $SIG{__DIE__};
    eval {
        require Win32::TieRegistry;
        Win32::TieRegistry->import(Delimiter => '/');
    };
    unless($@ || not defined $Registry->{+HW_KEY}) {
        $REG = $Registry->{+CPU_KEY};
    }
}

sub load {
    my $self = shift;
    return 0; # Fix this !!!!!
}

# arabirim belirsiz. contexte göre veri döndür !!!
# cpu_num adlý bir parametre al, buna göre cpu özellik döndür
# veya properties() adlý bir metod ekle!!!
sub identify {
    my $self = shift;
    return $self->_serve_from_cache(wantarray) if $self->{CACHE};

    my @cpu; # try sequence: WMI -> Registry -> Environment
    @cpu = $self->wmi_cpu             if !$self->{disable_si};
    @cpu = $self->_fetch_from_reg     if !@cpu && $self->_registry_is_ok;
    @cpu = $self->SUPER::identify(@_) if !@cpu;
    die "Failed to identify CPU"      if !@cpu;
    $self->{CACHE} = [@cpu];

    return $self->_serve_from_cache(wantarray);
}

# ------------------------[ P R I V A T E ]------------------------ #

# $REG->{'0/FeatureSet'}
# $REG->{'0/Update Status'}
sub _fetch_from_reg {
    my $self = shift;
    my($name, @cpu);

    foreach my $k (keys %{ $REG }) {
        $name = $REG->{ $k . '/ProcessorNameString' };
        $name =~ s{\A \s+}{}xms;
        push @cpu, {
            name          => $name,
            speed         => hex( $REG->{ $k . '/~MHz' } ),
            data_width    => undef,
            bus_speed     => undef,
            address_width => undef,
        };
    }

    return @cpu;
}

sub _registry_is_ok {
    my $self = shift;
    return if not $REG;
    return if not $REG->{'0/'};
    return if not $REG->{'0/ProcessorNameString'};
    return 1;
}

# may be called from ::Env
sub __env_pi {
    my $self = shift;
    return if not $REG;
    return $REG->{'0/Identifier'}.', '.$REG->{'0/VendorIdentifier'};
}

1;

__END__
