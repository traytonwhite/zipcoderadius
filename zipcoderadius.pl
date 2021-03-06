#!/usr/bin/env perl

use Mojolicious::Lite;
use DBI;
use Math::Trig qw( great_circle_distance deg2rad );

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

app->secret('passphrase does not matter');

my $dbh = DBI->connect('dbi:Pg:dbname=zipcodes','trayton','', {AutoCommit => 1})
    or die "Could not connect to database.";

# quick reference to the db handle
helper db => sub { $dbh };

# create helper method for selecting zip codes from db
helper selectzips => sub {
    my %ziphash;
    my $earthradius;
    my $self = shift;
    my ( $zipcode, $radius, $units ) = @_;
    if ( $units eq 'miles' ) {
        $earthradius = 3963;
    } else {
        $earthradius = 6378;
    }
    my $allzipq = eval { $self->db->prepare("select zip, lat, lon
            from ziplatlon") } || return undef;
    $allzipq->execute();
    my $allzips = $allzipq->fetchall_hashref('zip');
    return $self->distancezips( $zipcode, $radius, $earthradius, $allzips );
};

# helper method to calculate distances and build hash of those zips within
# radius
helper distancezips => sub {
    my $self = shift;
    my ( $zipcode, $radius, $earthradius, $ziplatlonhash ) = @_;
    my %returnhash;
    for my $zip ( keys %{$ziplatlonhash} ) {
        # calculate the distance between the 2 zip codes
        my $distance = great_circle_distance(
            deg2rad($ziplatlonhash->{$zipcode}{'lon'}),
            deg2rad(90 - $ziplatlonhash->{$zipcode}{'lat'}),
            deg2rad($ziplatlonhash->{$zip}{'lon'}),
            deg2rad(90 - $ziplatlonhash->{$zip}{'lat'}),
            $earthradius
        );
        $distance = sprintf("%.2f", $distance);
        # add the zip code to the hash only if it's within the radius
        if ( $distance <= $radius ) {
            $returnhash{$zip}{'distance'} = $distance;
            $returnhash{$zip}{'lon'} = $ziplatlonhash->{$zip}{'lon'};
            $returnhash{$zip}{'lat'} = $ziplatlonhash->{$zip}{'lat'};
        }
    }
    return \%returnhash;
};

# grabs any of the routes and pushes through to single page
any '/' => sub {
    my $self    = shift;
    my $zipcode = $self->param('zipcode');
    my $radius  = $self->param('radius');
    my $units   = $self->param('units');
    my $zips;
    if ( $zipcode ) {
        $zips = $self->selectzips($zipcode, $radius, $units);
    } else {
        $zipcode = 'starter';
        $zips = {
            'starter' => {
                'lat' => -94.23,
                'lon' => 38.55,
                'distance' => 0
            },
        };
    }
    $self->stash( zipcodehash => $zips );
    $self->stash( zipcode => $zipcode );
    $self->render('index');
};

app->start;

__DATA__

@@ index.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>Zip Code Radius</title>
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
    <style type="text/css">
      html { height: 90%; width: 95% }
      body { height: 90%; width: 95%; margin-left: auto; margin-right: auto; padding: 0 }
      #map-canvas { height: 90%; width: 100% }
    </style>
    <script type="text/javascript"
      src="https://maps.googleapis.com/maps/api/js?key=&sensor=false">
    </script>
    <script type="text/javascript">
      function initialize() {
        var mapOptions = {
          center: new google.maps.LatLng(<%= $zipcodehash->{$zipcode}{'lat'}%>, <%= $zipcodehash->{$zipcode}{'lon'} %>),
          zoom: 4,
          mapTypeId: google.maps.MapTypeId.ROADMAP
        };
        var map = new google.maps.Map(document.getElementById("map-canvas"),
          mapOptions);
      }
      google.maps.event.addDomListener(window, 'load', initialize);
    </script>
  </head>
  <body>
  <table>
    <div id="map-canvas"/>
    </table>
<br>
<center>    <table>
<form action="<%=url_for('')->to_abs%>" method="post">
    Zip Code:   <input type="text" name="zipcode">
    Radius:     <input type="text" name="radius">
    Units:      <input type="radio" name="units" value="km"> km
                <input type="radio" name="units" value="miles"> miles
    <br>
                <input type="submit" value="Calculate">
</form>
<br>
<br>
<table border="1">
    <tr>
        <th>Zip Code</th>
        <th>Distance</th>
    </tr>
    % for my $zip ( sort { $zipcodehash->{$a}{'distance'} <=> $zipcodehash->{$b}{'distance'} || $a <=> $b } keys %{$zipcodehash} ) {
        <tr>
        <td><%= $zip %></td>
        <td><%= $zipcodehash->{$zip}{'distance'} %></td>
        </tr>
    % }
</table>
</table>
</center>
</body>
</html>

