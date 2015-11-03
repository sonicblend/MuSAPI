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
    {code => 200, body => slurp 't/responses/googleweb_single_result.txt'},
    # success, empty set
    {code => 200, body => slurp 't/responses/googleweb_no_results.txt'},
    # forbidden
    {code => 403, body => slurp 't/responses/googleweb_forbidden.txt'},
];

plugin 'MuSAPI::Plugin::FakeCache' => $test_results;
plugin 'MuSAPI::Plugin::Query::GoogleWeb::Bandcamp';

get '/' => sub {
    my $self = shift;
    my $cb = sub {
        my $json = shift;
        return MuSAPI::Controller::Search::_render_result($self, $json);
    };
    $self->query_googleweb_bandcamp($self->param('q'), $cb);
    $self->render_later;
};

my $t = Test::Mojo->new;
$t->get_ok('/?q=Peter Broderick & Machinefabriek - Blank Grey Canvas Sky')->status_is(200)->json_is({
    title   => 'Blank Grey Canvas Sky | Machinefabriek',
    link    => 'http://machinefabriek.bandcamp.com/album/blank-grey-canvas-sky',
});
$t->get_ok('/?q=Damon Albarn - Everyday Robots')->status_is(200)->json_is({not_found => 1});
$t->get_ok('/?q=asdfasdfasdfasdfasdfasdf')->status_is(500)->json_is({});

done_testing();
