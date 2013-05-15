#!/usr/bin/env perl
#===============================================================================
#
#         FILE: loadzipcodestopgdb.pl
#
#        USAGE: ./loadzipcodestopgdb.pl
#
#  DESCRIPTION: Read the zip code CSV file and load into PostgreSQL DB
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Trayton White (tbw), tbw@traytonwhite.com
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 05/11/2013 10:44:26 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Text::CSV;
use DBI;

my $dbh = DBI->connect('dbi:Pg:dbname=zipcodes','trayton','', {AutoCommit => 1})
    or die "Could not connect.";

$dbh->do('create table ziplatlon (
        zip char(5),
        lon real,
        lat real
    )'
);

my $sth = $dbh->prepare("insert into ziplatlon values (?, ?, ?)");

my $csv = Text::CSV->new( { binary => 1 } );
open my $fh, "<", $ARGV[0] or die "ARGV[0]: $!\n";

my $header = $csv->getline( $fh );
my @zipfield = grep { $header->[$_] =~ /Zipcode/ } 0..$#{$header};
my @lonfield = grep { $header->[$_] =~ /Long/i } 0..$#{$header};
my @latfield = grep { $header->[$_] =~ /Lat/i } 0..$#{$header};

while ( my $row = $csv->getline( $fh ) ) {
    my $zip = $row->[$zipfield[0]];
    my $lon = $row->[$lonfield[0]];
    my $lat = $row->[$latfield[0]];
    next if ( $lon eq "" );
    $sth->execute(
        $zip,
        $lon,
        $lat
    );
}

close $fh;
my $rc = $dbh->disconnect;
