use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MuSAPI');
$t->get_ok('/search/deezer/Aphex Twin – Syro')
  ->status_is(200)
  ->json_is('/total', 1) # expect a single result - if not, data may not match
  ->json_has('/data')
  ->json_has('/data/0')
  ->json_has('/data/0/id')
  ->json_is('/data/0/link', 'http://www.deezer.com/album/8664043');

$t->get_ok('/search/deezer/Benjamin Clementine – At Least for Now')
  ->status_is(200)
  ->json_is('/total', 1) # expect a single result - if not, data may not match
  ->json_is('/data/0/link', 'http://www.deezer.com/album/9787118');

$t->get_ok('/search/bandcamp/Liquid Stranger - The Intergalactic Slapstick')
  ->status_is(200)
  ->json_is('/title', 'The Intergalactic Slapstick | Liquid Stranger')
  ->json_is('/link', 'https://liquidstranger.bandcamp.com/album/the-intergalactic-slapstick');

$t->get_ok('/search/bandcamp/The Cyclist - Hot House')
  ->status_is(200)
  ->json_is('/title', 'Hot House EP | music/is/for/losers')
  ->json_is('/link', 'https://musicisforlosers.bandcamp.com/album/hot-house-ep');

done_testing();
