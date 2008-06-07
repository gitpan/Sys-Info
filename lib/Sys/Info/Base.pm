package Sys::Info::Base;
use strict;
use vars qw( $VERSION );
use constant WEEKDAYS => qw( Sun Mon Tue Wed Thu Fri Sat );
use constant MONTHS   => qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
use constant MKTIME_YDAY  =>  0;
use constant MKTIME_ISDST => -1;
use IO::File;
use Carp qw( croak );
use Sys::Info qw( OSID );

$VERSION = '0.50';

my %LOAD_MODULE; # cache

sub load_subclass { # hybrid: static+method
    my $self     = shift;
    my $template = shift || croak "Template missing for load_subclass()";

    my $class = sprintf $template, OSID;
    (my $file  = $class) =~ s{::}{/}xmsg;
    eval { require $file . '.pm'; };
    if ( $@ ) {
        my $t = "Operating system identified as: '%s'. Unable to load sub class %s: %s";
        croak sprintf( $t, OSID, $class, $@ );
    }
    return $class;
}

sub load_module {
    my $self  = shift;
    my $class = shift || croak "Which class to load?";
    croak "Invalid class name: $class" if ref $class;
    return $class if $LOAD_MODULE{ $class };
    my $check = $class;
    $check =~ tr/a-zA-Z0-9_://d;
    croak "Invalid class name: $class" if $check;
    require File::Spec;
    my $file = File::Spec->catfile( split /::/, $class) . '.pm';
    eval { require $file; };
    croak "Error loading $class: $@" if $@;
    $LOAD_MODULE{ $class } = 1;
    return $class;
}

sub trim {
    my $self = shift;
    my $str  = shift;
    return if not defined $str;
    return $str if not $str;
    $str =~ s{ \A \s+    }{}xms;
    $str =~ s{    \s+ \z }{}xms;
    $str;
}

sub slurp { # fetches all data inside a flat file
    my $self   = shift;
    my $file   = shift;
    my $msgerr = shift || 'I can not open file %s for reading: ';
    my $FH     = IO::File->new;
       $FH->open($file) or croak sprintf($msgerr, $file) . $!;
    my $slurped;
    SLURP_SCOPE: {
       local $/;
       chomp($slurped = <$FH>);
    }
    close  $FH;
    return $slurped;
}

sub read_file {
    my $self   = shift;
    my $file   = shift;
    my $msgerr = shift || 'I can not open file %s for reading: ';
    my $FH     = IO::File->new;
       $FH->open($file) or die sprintf($msgerr, $file) . $!;
    my @flat   = <$FH>;
    close  $FH;
    return @flat;
}

sub date2time { # date stamp to unix time stamp conversion
    my $self   = shift;
    my $stamp  = shift || die "No date input specified!";
    my($i, $j) = (0,0); # index counters
    my %wdays  = map { $_ => $i++ } WEEKDAYS;
    my %months = map { $_ => $j++ } MONTHS;
    my @junk   = split /\s+/, $stamp;
    my $reg    = join    '|', keys %wdays;

    # remove until ve get a day name
    while ( @junk && $junk[0] !~ m{ \A ($reg) \z }xmsi ) {
       shift @junk;
    }
    return '' if ! @junk;

    my($wday, $month, $mday, $time, $zone, $year) = @junk;
    my($hour, $min, $sec)                         = split /\:/, $time;

    require POSIX;
    my $unix =  POSIX::mktime(
                    $sec,
                    $min,
                    $hour,
                    $mday,
                    $months{$month},
                    $year - 1900,
                    $wdays{$wday},
                    MKTIME_YDAY,
                    MKTIME_ISDST,
                );

    return $unix;
}

1;

__END__
