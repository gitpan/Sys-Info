package Sys::Info::Driver::Unknown::Device::CPU;
use strict;
use vars qw($VERSION);
use base qw(Sys::Info::Driver::Unknown::Device::CPU::Env);

$VERSION = '0.60';

BEGIN {
    local $SIG{__DIE__};
    eval {
        require Unix::Processors;
        Unix::Processors->import;
        1;
    };
    my $UP = $@ ? 0 : 1;
    *_UPOK = sub {$UP};
}

sub load {0}

sub identify {
    my $self = shift;
    return $self->_serve_from_cache(wantarray) if $self->{CACHE};

    my @cpu;
    if ( _UPOK ) {
        my $up = Unix::Processors->new;
        foreach my $proc ( @{ $up->processors } ) {
            push @cpu, {
                processor_id                 => $proc->id, # cpu id 0,1,2,3...
                data_width                   => undef,
                address_width                => undef,
                bus_speed                    => undef,
                speed                        => $proc->clock,
                name                         => $proc->type,
                family                       => undef,
                manufacturer                 => undef,
                model                        => undef,
                stepping                     => undef,
                number_of_cores              => $up->max_physical,
                number_of_logical_processors => $up->max_online,
                L1_cache                     => undef,
                flags                        => undef,
            };
        }
    } else {
        @cpu = $self->SUPER::identify(@_);
    }

    $self->{CACHE} = [ @cpu ];
    return $self->_serve_from_cache(wantarray);
}

1;

__END__

=head1 NAME

Sys::Info::Driver::Unknown::Device::CPU - Compatibility layer for unsupported platforms

=head1 SYNOPSIS

-

=head1 DESCRIPTION

L<Unix::Processors> is recommended for
unsupported platforms.

=head1 METHODS

=head2 identify

See identify in L<Sys::Info::Device::CPU>.

=head2 load

See load in L<Sys::Info::Device::CPU>.

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::CPU>, L<Unix::Processors>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
