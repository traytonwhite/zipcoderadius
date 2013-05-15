#!/usr/bin/env perl
#===============================================================================
#
#         FILE: zipcodedistance.pl
#
#        USAGE: ./zipcodedistance.pl
#
#  DESCRIPTION: Subroutine here calculates distance between 2 zip codes
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Trayton White (tbw), tbw@traytonwhite.com
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 05/08/2013 12:13:39 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Math::Trig qw( great_circle_distance );

sub zipdistance {
    my  ( $ziplatlonhash, $radius ) = @_;
    my %returnhash;
    for my $zipcode ( keys %{$ziplatlonhash} ) {
        for ( keys %{$ziplatlonhash} ) {
            if ( $zipcode eq $_ ) {
                $returnhash{$zipcode}{$_} = 0;
            } else {
                $returnhash{$zipcode}{$_} = &great_circle_distance(
                    ${$ziplatlonhash}{$zipcode}{'lon'},
                    90 - ${$ziplatlonhash}{$zipcode}{'lat'},
                    ${$ziplatlonhash}{$_}{'lon'},
                    90 - ${$ziplatlonhash}{$_}{'lat'},
                    $radius
                )
            }
        }
    }
    return \%returnhash;
} ## --- end sub zipdistance


my %zipdb = (
        '94123' => {
            'lat' => 37.8,
            'lon' => -122.4,
        },
        '46714' => {
            'lat' => 40.7,
            'lon' => -85.2,
        },
        '48126' => {
            'lat' => 44.8,
            'lon' => -80.3,
        },
        '00501' => {
            'lat' => 30.2,
            'lon' => -70.3,
    },
);

my $final = &zipdistance( \%zipdb, 6378 );

print Dumper( \$final );

