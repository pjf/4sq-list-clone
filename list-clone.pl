#!/usr/bin/perl -w
use v5.12;
use strict;
use warnings;
use autodie;
use Encode;

use WWW::Mechanize;
use JSON::Any;
use Data::Dumper;
use Config::Tiny;

my $config = Config::Tiny->read('4sq.ini');

my $TOKEN="oauth_token=$config->{auth}{token}&v=20121108";
my $BASE ='https://api.foursquare.com/v2';

my $mech = WWW::Mechanize->new();
my $json = JSON::Any->new;

# Scrape Jesse's list.
# TODO: Read lists to merge from a file.

$mech->get( "$BASE/lists/4e4a11f02271ac3f6bd05d70?$TOKEN" );

my $data = $json->decode( $mech->content );

# Walk through the venues and add them.

foreach my $venue ( @{ $data->{response}{list}{listItems}{items} }) {

    my $name = $venue->{venue}{name};
    my $id   = $venue->{venue}{id};

    say "Adding $name ($id)";

    # TODO: Check for (and don't add) duplicates.
    # TODO: Set the text for each list from upstream.
    # TODO: Inherit tips, etc.

    $mech->post(
        "$BASE/lists/50933738e4b07ae1b6203788/additem?$TOKEN",
        {
            venueId => $id,
            text    => "Courtesy Jesse Vincent (Wifi + Coffee + Power)",
        }
    );
}
