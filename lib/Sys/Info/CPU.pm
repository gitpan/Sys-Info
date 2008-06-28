package Sys::Info::CPU;
use strict;
use vars qw( $VERSION );
use base qw( Sys::Info::Device::CPU );
use Sys::Info qw( _deprecate );

$VERSION = '0.50';

_deprecate({
    msg  => "Use Sys::Info->device('CPU') instead.",
    name => "Sys::Info::CPU",
});

1;

__END__

=head1 NAME

Sys::Info::CPU - Deprecated CPU Class

=head1 SYNOPSIS

Deprecated.

=head1 DESCRIPTION

Deprecated. Use Sys::Info->device('CPU') instead.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
