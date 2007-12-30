package Sys::Info::Driver::Windows::OS::Net;
use strict;
use vars qw($VERSION);
use Win32;
use constant IS_WIN95        => Win32::IsWin95();
use constant USER_INFO_LEVEL => 3;

$VERSION = '0.50';

BEGIN {
    if ( ! IS_WIN95 ) {
        # Win32API::Net: 0.13  Thu Sep 17 19:35:20 1998
        # Some changes : 0.15  Sat Sep 25 15:53:02 1999
        # seems OK ot use.
        require Win32API::Net;
        Win32API::Net->import( qw() );
    }
}

sub _user_get_info {
    return +() if IS_WIN95;
    my $self   = shift;
    my $user   = shift || return;
    my $server = Sys::Info::Driver::Windows::OS->node_name();
    my %info;
    Win32API::Net::UserGetInfo( $server, $user, USER_INFO_LEVEL, \%info );
    return %info;
}

sub user_fullname {
    my $self = shift;
    my $user = shift || return;
    my %info = $self->_user_get_info( $user );
    return $info{fullName};
    # $info{comment}
}

sub user_logon_server {
    my $self = shift;
    my $user = shift || return;
    my %info = $self->_user_get_info( $user );
    return $info{logonServer};
    # $info{comment}
}

1;