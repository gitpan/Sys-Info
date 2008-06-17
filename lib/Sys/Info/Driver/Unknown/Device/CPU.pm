package Sys::Info::Driver::Unknown::Device::CPU;
use strict;
use vars qw($VERSION);
use base qw(Sys::Info::Driver::Unknown::Device::CPU::Env);

$VERSION = '0.50';

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
        my $procs = Unix::Processors->new;
        #$procs->max_online;
        #$procs->max_clock;
        #$procs->max_physical;
        #if ($procs->max_online != $procs->max_physical) {
        #    print "Hyperthreading between ",$procs->max_physical," physical CPUs.\n";
        #}
        foreach my $proc ( @{ $procs->processors } ) {
            push @cpu, {
                data_width    => undef,
                address_width => undef,
                bus_speed     => undef,
                speed         => $proc->clock,
                name          => $proc->type,
                #id            => $proc->id,    # cpu id 0,1,2,3...
                #state         => $proc->state, # online/offline/poweroff
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

Nothing public here.

=head1 DESCRIPTION

Nothing public here. L<Unix::Processors> is recommended for
unsupported platforms.

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
