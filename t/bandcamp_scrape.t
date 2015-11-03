use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use MuSAPI::Plugin::FakeCache;
use MuSAPI::Controller::Search;

use Mojo::Util qw/slurp/;
use Mojolicious::Lite;

# Mock the responses the Bandcamp Custom Search may return

my $test_results = [
    # success, single result
    {code => 200, body => slurp 't/responses/bandcamp_result.txt'},
    # success, unexpected empty page
    {code => 200, body => 'nothing to see here folks'},
    # internal server error
    {code => 500, body => ''},
    {code => 404, body => slurp 't/responses/bandcamp_404.txt'},
];

plugin 'MuSAPI::Plugin::FakeCache' => $test_results;
plugin 'MuSAPI::Plugin::Query::Bandcamp::Scrape';

get '/' => sub {
    my $self = shift;
    my $cb = sub {
        my $json = shift;
        return MuSAPI::Controller::Search::_render_result($self, $json);
    };
    $self->query_bandcamp_scrape($self->param('q'), $cb);
    $self->render_later;
};

my $t = Test::Mojo->new;
$t->get_ok('/?q=https://machinefabriek.bandcamp.com/album/blank-grey-canvas-sky')->status_is(200)->json_is({
    artist  => 'Peter Broderick & Machinefabriek',
    title   => 'Blank Grey Canvas Sky',
    link    => 'http://machinefabriek.bandcamp.com/album/blank-grey-canvas-sky',
    id      => '2998386355',
});
$t->get_ok('/?q=https://beaconsound.bandcamp.com/album/peter-broderick-gabriel-saloman')->status_is(200)->json_is({not_found => 1});
$t->get_ok('/?q=https://beaconsound.bandcamp.com/album/peter-broderick-gabriel-saloman')->status_is(500)->json_is({});
$t->get_ok('/?q=https://machinefabriek.bandcamp.com/album/cats-dogs-mice')->status_is(500)->json_is({});

done_testing();
