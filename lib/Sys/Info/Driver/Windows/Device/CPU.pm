package Sys::Info::Driver::Windows::Device::CPU;
use strict;
use vars     qw( $VERSION @ISA $Registry );
use base qw(
    Sys::Info::Driver::Unknown::Device::CPU::Env
    Sys::Info::Driver::Windows::Device::CPU::WMI
);
use Sys::Info::Constants qw( :windows_reg );

$VERSION = '0.60';

my $REG;
TRY_TO_LOAD: {
    # SetDualVar req. in Win32::TieRegistry breaks any handler
    local $SIG{__DIE__};
    eval {
        require Win32::TieRegistry;
        Win32::TieRegistry->import(Delimiter => '/');
    };
    unless($@ || not defined $Registry->{+WIN_REG_HW_KEY}) {
        $REG = $Registry->{ +WIN_REG_CPU_KEY };
    }
}

sub load {
    my $self = shift;
    my @cpu  = $self->identify;
    return $cpu[0]->{load};
}

# arabirim belirsiz. contexte göre veri döndür !!!
# cpu_num adlý bir parametre al, buna göre cpu özellik döndür
# veya properties() adlý bir metod ekle!!!
sub identify {
    my $self = shift;
    return $self->_serve_from_cache(wantarray) if $self->{CACHE};

    my @cpu; # try sequence: WMI -> Registry -> Environment
    @cpu = $self->_fetch_from_wmi;
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
    my(@cpu);

    foreach my $k (keys %{ $REG }) {
        my $name = $REG->{ $k . '/ProcessorNameString' };
        $name =~ s{\s+}{ }xmsg;
        $name =~ s{\A \s+}{}xms;
        my $id = $REG->{ $k . '/Identifier' };

        push @cpu, {
            name          => $name,
            speed         => hex( $REG->{ $k . '/~MHz' } ),
            architecture  => ($id =~ m{ \A (.+?) \s? Family }xmsi),
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

=head1 NAME

Sys::Info::Driver::Windows::Device::CPU - Windows CPU Device Driver

=head1 SYNOPSIS

-

=head1 DESCRIPTION

Uses C<WMI>, C<Registry> and C<ENV> to identify the CPU.

=head1 METHODS

=head2 identify

See identify in L<Sys::Info::Device::CPU>.

=head2 load

See load in L<Sys::Info::Device::CPU>.

=head1 SEE ALSO

L<Sys::Info>,
L<Sys::Info::Device::CPU>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
