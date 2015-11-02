use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use MuSAPI::Plugin::FakeCache;
use MuSAPI::Controller::Search;

use Mojolicious::Lite;

# Mock the responses the Bandcamp Custom Search may return

my $test_results = [
    # success, single result
    {code => 200, body => '{"items":[{"link":"https://samleesong.bandcamp.com/album/ground-of-its-own","pagemap":{"musicalbum":[{"name":"Ground Of Its Own","byartist":"Sam Lee","image":"https://f1.bcbits.com/img/a0286867425_16.jpg","datepublished":"20120625","keywords":"contemporary folk"}],"metatags":[{"apple-mobile-web-app-capable":"yes","title":"Ground Of Its Own, by Sam Lee","og:title":"Ground Of Its Own, by Sam Lee","og:type":"album","og:site_name":"Sam Lee","og:description":"8 track album","twitter:title":"Ground Of Its Own, by Sam Lee","twitter:description":"8 track album","og:image":"https://f1.bcbits.com/img/a0286867425_5.jpg","og:url":"http://samleesong.bandcamp.com/album/ground-of-its-own","medium":"video","video_height":"105","video_width":"400","video_type":"application/x-shockwave-flash","og:video":"https://bandcamp.com/EmbeddedPlayer/v=2/album=811794327/size=large/tracklist=false/artwork=small/","og:video:secure_url":"https://bandcamp.com/EmbeddedPlayer/v=2/album=811794327/size=large/tracklist=false/artwork=small/","og:video:type":"text/html","og:video:height":"120","og:video:width":"400","fb:app_id":"165661066782720","twitter:site":"bandcamp","twitter:card":"player","twitter:player":"https://bandcamp.com/EmbeddedPlayer/v=2/album=811794327/size=large/linkcol=0084B4/notracklist=true/twittercard=true/","twitter:player:width":"350","twitter:player:height":"467","twitter:image":"https://f1.bcbits.com/img/a0286867425_2.jpg"}]}}]}'},
    # success, empty set
    {code => 200, body => '{}'},
    # internal server error, valid json
    {code => 500, body => '{}'},
    # internal server error, result not json
    {code => 500, body => ''},
    {code => 404, body => 'Wrong url silly'},
];

plugin 'MuSAPI::Plugin::FakeCache' => $test_results;
plugin 'MuSAPI::Plugin::Query::Bandcamp::CustomSearchAPI';

get '/' => sub {
    my $self = shift;
    my $cb = sub {
        my $json = shift;
        return MuSAPI::Controller::Search::_render_result($self, $json);
    };
    $self->query_bandcamp_cs($self->param('q'), $cb);
    $self->render_later;
};

my $t = Test::Mojo->new;
$t->get_ok('/?q=Sam Lee - Ground Of Its Own')->status_is(200)->json_is({
    artist  => 'Sam Lee',
    title   => 'Ground Of Its Own',
    link    => 'https://samleesong.bandcamp.com/album/ground-of-its-own',
    id      => '811794327'
});
$t->get_ok('/?q=abcdfergj')->status_is(200)->json_is({not_found => 1});
$t->get_ok('/?q=Sam Lee - Ground Of Its Own')->status_is(500)->json_is({});
$t->get_ok('/?q=Sam Lee - Ground Of Its Own')->status_is(500)->json_is({});
$t->get_ok('/?q=Sam Lee - Ground Of Its Own')->status_is(500)->json_is({});

done_testing();
