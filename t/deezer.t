use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use MuSAPI::Plugin::FakeCache;
use Mojolicious::Lite;
use MuSAPI::Controller::Search;

# Mock the responses Deezer may return
my $test_results = [
    # success, single result
    {code => 200, body => '{"data":[{"id":3426651,"title":"Ground Of Its Own","link":"http:\/\/www.deezer.com\/album\/3426651","cover":"http:\/\/api.deezer.com\/album\/3426651\/image","cover_small":"http:\/\/e-cdn-images.deezer.com\/images\/cover\/b802865107b7e9257e824c9195b64db3\/56x56-000000-80-0-0.jpg","cover_medium":"http:\/\/e-cdn-images.deezer.com\/images\/cover\/b802865107b7e9257e824c9195b64db3\/250x250-000000-80-0-0.jpg","cover_big":"http:\/\/e-cdn-images.deezer.com\/images\/cover\/b802865107b7e9257e824c9195b64db3\/500x500-000000-80-0-0.jpg","genre_id":-1,"nb_tracks":8,"record_type":"album","tracklist":"http:\/\/api.deezer.com\/album\/3426651\/tracks","explicit_lyrics":false,"artist":{"id":288646,"name":"Sam Lee","link":"http:\/\/www.deezer.com\/artist\/288646","picture":"http:\/\/api.deezer.com\/artist\/288646\/image","picture_small":"http:\/\/e-cdn-images.deezer.com\/images\/artist\/\/56x56-000000-80-0-0.jpg","picture_medium":"http:\/\/e-cdn-images.deezer.com\/images\/artist\/\/250x250-000000-80-0-0.jpg","picture_big":"http:\/\/e-cdn-images.deezer.com\/images\/artist\/\/500x500-000000-80-0-0.jpg","tracklist":"http:\/\/api.deezer.com\/artist\/288646\/top?limit=50","type":"artist"},"type":"album"}],"total":1}'},
    # success, multiple results
    {code => 200, body => '{"data":[{"id":11472122,"title":"At Least For Now","link":"http:\/\/www.deezer.com\/album\/11472122","cover":"http:\/\/api.deezer.com\/album\/11472122\/image","cover_small":"http:\/\/e-cdn-images.deezer.com\/images\/cover\/ce548cfd90cf6b9df2c690f19bd349c9\/56x56-000000-80-0-0.jpg","cover_medium":"http:\/\/e-cdn-images.deezer.com\/images\/cover\/ce548cfd90cf6b9df2c690f19bd349c9\/250x250-000000-80-0-0.jpg","cover_big":"http:\/\/e-cdn-images.deezer.com\/images\/cover\/ce548cfd90cf6b9df2c690f19bd349c9\/500x500-000000-80-0-0.jpg","genre_id":85,"nb_tracks":15,"record_type":"album","tracklist":"http:\/\/api.deezer.com\/album\/11472122\/tracks","explicit_lyrics":false,"artist":{"id":4806921,"name":"Benjamin Clementine","link":"http:\/\/www.deezer.com\/artist\/4806921","picture":"http:\/\/api.deezer.com\/artist\/4806921\/image","picture_small":"http:\/\/e-cdn-images.deezer.com\/images\/artist\/f580dc2c87a6d5320a312cfad114cf7b\/56x56-000000-80-0-0.jpg","picture_medium":"http:\/\/e-cdn-images.deezer.com\/images\/artist\/f580dc2c87a6d5320a312cfad114cf7b\/250x250-000000-80-0-0.jpg","picture_big":"http:\/\/e-cdn-images.deezer.com\/images\/artist\/f580dc2c87a6d5320a312cfad114cf7b\/500x500-000000-80-0-0.jpg","tracklist":"http:\/\/api.deezer.com\/artist\/4806921\/top?limit=50","type":"artist"},"type":"album"},{"id":9787118,"title":"At Least For Now","link":"http:\/\/www.deezer.com\/album\/9787118","cover":"http:\/\/api.deezer.com\/album\/9787118\/image","cover_small":"http:\/\/e-cdn-images.deezer.com\/images\/cover\/70b2b5e0aeca8fc536736d96aba1b443\/56x56-000000-80-0-0.jpg","cover_medium":"http:\/\/e-cdn-images.deezer.com\/images\/cover\/70b2b5e0aeca8fc536736d96aba1b443\/250x250-000000-80-0-0.jpg","cover_big":"http:\/\/e-cdn-images.deezer.com\/images\/cover\/70b2b5e0aeca8fc536736d96aba1b443\/500x500-000000-80-0-0.jpg","genre_id":85,"nb_tracks":11,"record_type":"album","tracklist":"http:\/\/api.deezer.com\/album\/9787118\/tracks","explicit_lyrics":false,"artist":{"id":4806921,"name":"Benjamin Clementine","link":"http:\/\/www.deezer.com\/artist\/4806921","picture":"http:\/\/api.deezer.com\/artist\/4806921\/image","picture_small":"http:\/\/e-cdn-images.deezer.com\/images\/artist\/f580dc2c87a6d5320a312cfad114cf7b\/56x56-000000-80-0-0.jpg","picture_medium":"http:\/\/e-cdn-images.deezer.com\/images\/artist\/f580dc2c87a6d5320a312cfad114cf7b\/250x250-000000-80-0-0.jpg","picture_big":"http:\/\/e-cdn-images.deezer.com\/images\/artist\/f580dc2c87a6d5320a312cfad114cf7b\/500x500-000000-80-0-0.jpg","tracklist":"http:\/\/api.deezer.com\/artist\/4806921\/top?limit=50","type":"artist"},"type":"album"}],"total":2}'},
    # success, empty set
    {code => 200, body => '{"data":[],"total":0}'},
    # internal server error, valid json
    {code => 500, body => '{}'},
    # internal server error, result not json
    {code => 500, body => ''},
    {code => 404, body => 'Wrong url silly'},
];

plugin 'MuSAPI::Plugin::FakeCache' => $test_results;
plugin 'MuSAPI::Plugin::Query::Deezer';

get '/' => sub {
    my $self = shift;
    my $cb = sub {
        my $json = shift;
        return MuSAPI::Controller::Search::_render_result($self, $json);
    };
    $self->query_deezer($self->param('q'), $cb);
    $self->render_later;
};

my $t = Test::Mojo->new;
$t->get_ok('/?q=Sam Lee - Ground Of Its Own')->status_is(200)->json_is({
    artist  => 'Sam Lee',
    title   => 'Ground Of Its Own',
    link    => 'http://www.deezer.com/album/3426651',
    id      => '3426651'
});
# MuSAPI ignores the second result
$t->get_ok('/?q=Benjamin Clementine - At Least For Now')->status_is(200)->json_is({
    artist  => 'Benjamin Clementine',
    title   => 'At Least For Now',
    link    => 'http://www.deezer.com/album/11472122',
    id      => '11472122'
});
$t->get_ok('/?q=abcdfergj')->status_is(200)->json_is({not_found => 1});
$t->get_ok('/?q=Sam Lee - Ground Of Its Own')->status_is(500)->json_is({});
$t->get_ok('/?q=Sam Lee - Ground Of Its Own')->status_is(500)->json_is({});
$t->get_ok('/?q=Sam Lee - Ground Of Its Own')->status_is(500)->json_is({});

done_testing();
