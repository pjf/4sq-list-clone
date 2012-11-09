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
use YAML::Any qw(LoadFile);

# Get ready for using the 4SQ API.

my $authconf = Config::Tiny->read('4sq.ini');

my $TOKEN="oauth_token=$authconf->{auth}{token}&v=20121108";
my $BASE ='https://api.foursquare.com/v2';

my $mech = WWW::Mechanize->new();
my $json = JSON::Any->new;

# Read our config

my $config = LoadFile("lists.yml");

foreach my $list ( @{ $config->{lists} } ) {
    say "Building $list->{name}";

    my %already_on_list;

    # Record everything on the list, so we don't add them twice.
    foreach my $venue ( @{ get_venues_in_list($list->{id}) } ) {
        $already_on_list{$venue->{venue}{id}}++;
    }

    # Walk through all the lists we feed from...
    foreach my $upstream ( @{ $list->{from} } ) {

        my $listinfo = get_list($upstream);

        my $author   = "$listinfo->{user}{firstName} $listinfo->{user}{lastName}";
        my $listname = $listinfo->{name};

        foreach my $venue ( @{ get_venues_in_list($upstream) } ) {

            my $venue_id = $venue->{venue}{id};

            next if $already_on_list{$venue_id};

            my $credit = "Courtesy $listname by $author";

            say "* Adding $venue->{venue}{name} ($credit)";

            # TODO: Inherit tips, etc.

            add_to_list($list->{id}, $venue_id, $credit);
        }
    }
}

# TODO: Turn these into a proper OO module

sub get_venues_in_list {
    my ($list_id) = @_;

    return get_list($list_id)->{listItems}{items};
}

# Get a list, and also cache it.
sub get_list {
    my ($list_id) = @_;

    state %cache;

    return $cache{$list_id} if $cache{$list_id};

    $mech->get("$BASE/lists/$list_id?$TOKEN");

    $cache{$list_id} = $json->decode( $mech->content )->{response}{list};

    return $cache{$list_id};
}

sub add_to_list {
    my ($list, $venue, $text) = @_;

    $mech->post(
        "$BASE/lists/$list/additem?$TOKEN",
        {
            venueId => $venue,
            text    => $text,
        }
    );
}
