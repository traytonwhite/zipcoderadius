#!/usr/bin/env perl
#===============================================================================
#
#         FILE: zipcodescript.pl
#
#        USAGE: ./zipcodescript.pl
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
use Math::Trig qw( great_circle_distance deg2rad );
use Data::Dumper;

my $file = $ARGV[0] or
    die "Please list a zip code csv file when calling this command.\n";

open(my $data, '<', $file) or die "Failed to open '$file' $!\n";

# This section reads in the first line of the CSV file, and looks for the
# zipcode, latitude, and longitude fields.
chomp(my $header = <$data>);
# Assume the zip code file has a header row
my @fieldnames = split(',', $header);
# Find field with zip codes
my @zipfield = grep { $fieldnames[$_] =~ /zip/ } 0..$#fieldnames;
# Find field with longitude
my @lonfield = grep { $fieldnames[$_] =~ /longitude/ } 0..$#fieldnames;
# Find field with latitude
my @latfield = grep { $fieldnames[$_] =~ /latitude/ } 0..$#fieldnames;

my %zipdb;

while ( my $line = <$data>) {
    chomp($line);
    $line =~ s/"//g;
    my @splitline = split(',', $line);
    if ($splitline[$lonfield[0]] == 0) {
        next; # if the longitude is 0, then it's not real for a US address
    } elsif (exists $zipdb{$splitline[$zipfield[0]]}) {
        next;
    } else {
    $zipdb{$splitline[$zipfield[0]]}{'lon'} = $splitline[$lonfield[0]];
    $zipdb{$splitline[$zipfield[0]]}{'lat'} = $splitline[$latfield[0]];
    }
}
close($data);

&zipdistance( 6378.14, 500 );

sub zipdistance {
    my  ( $radius, $mindist ) = @_;
    for my $zipcode ( keys %zipdb ) {
        my %zipdist;
        for ( keys %zipdb ) {
            if ( $zipcode eq $_ ) {
                $zipdist{$_} = 0;
            } elsif ( $zipcode gt $_ ) {
                next;
            } else {
                my $distance = sprintf("%.2f", &great_circle_distance (
                    deg2rad($zipdb{$zipcode}{'lon'}),
                    deg2rad(90 - $zipdb{$zipcode}{'lat'}),
                    deg2rad($zipdb{$_}{'lon'}),
                    deg2rad(90 - $zipdb{$_}{'lat'}),
                    $radius
                ));
                $zipdist{$_} = $distance if ( $distance < $mindist );
                }
            }
        for ( keys %zipdist ) {
        print $zipcode, ",", $_, ",", $zipdist{$_}, "\n";
        }
    }
} ## --- end sub zipdistance


#print Dumper( \$zipdistancehash );

#print Dumper( \%zipdb );
#print Dumper( \@fieldnames );
#print Dumper( \@zipfield );
#print Dumper( \@lonfield );
#print Dumper( \@latfield );

