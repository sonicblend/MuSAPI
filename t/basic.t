use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MuSAPI');
$t->get_ok('/search/deezer/Aphex Twin – Syro')
  ->status_is(200)
#  ->json_is('/total', 1) # expect a single result - if not, data may not match
  ->json_is('/artist', 'Aphex Twin')
  ->json_is('/title',  'Syro')
  ->json_is('/id',     '8664043')
  ->json_is('/link',   'http://www.deezer.com/album/8664043');

$t->get_ok('/search/deezer/Benjamin Clementine – At Least for Now')
  ->status_is(200)
#  ->json_is('/total', 1) # expect a single result - if not, data may not match
  ->json_is('/artist', 'Benjamin Clementine')
  ->json_is('/title',  'At Least For Now')
  ->json_is('/id',     '9787118')
  ->json_is('/link',   'http://www.deezer.com/album/9787118');

$t->get_ok('/search/bandcamp/Liquid Stranger - The Intergalactic Slapstick')
  ->status_is(200)
  ->json_is('/link',   'http://liquidstranger.bandcamp.com/album/the-intergalactic-slapstick')
  ->json_is('/artist', 'Liquid Stranger')
  ->json_is('/title',  'The Intergalactic Slapstick')
  ->json_is('/id',     '4283774662');

$t->get_ok('/search/bandcamp/The Cyclist - Hot House')
  ->status_is(200)
  ->json_is('/link',   'http://musicisforlosers.bandcamp.com/album/hot-house-ep')
  ->json_is('/artist', 'The Cyclist')
  ->json_is('/title',  'Hot House EP')
  ->json_is('/id',     '3302283349');

done_testing();
