use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('PlayLister');
$t->get_ok('/search/deezer/Aphex Twin – Syro')
  ->status_is(200)
#  ->json_is('/total', 1) # expect a single result - if not, data may not match
  ->json_is('/artist', 'Aphex Twin')
  ->json_is('/title',  'Syro')
  ->json_is('/link',   'http://www.deezer.com/album/8664043');

$t->get_ok('/search/deezer/Benjamin Clementine – At Least for Now')
  ->status_is(200)
#  ->json_is('/total', 1) # expect a single result - if not, data may not match
  ->json_is('/artist', 'Benjamin Clementine')
  ->json_is('/title',  'At Least For Now')
  ->json_is('/link',   'http://www.deezer.com/album/9787118');

$t->get_ok('/search/bandcamp/Liquid Stranger - The Intergalactic Slapstick')
  ->status_is(200)
  ->json_is('/title', 'The Intergalactic Slapstick | Liquid Stranger')
  ->json_is('/link', 'https://liquidstranger.bandcamp.com/album/the-intergalactic-slapstick');

TODO: {
    local $TODO = 'Get artist and title direct from bandcamp page';

    $t->json_is('/artist', 'Liquid Stranger')
      ->json_is('/title',  'The Intergalactic Slapstick');
}

$t->get_ok('/search/bandcamp/The Cyclist - Hot House')
  ->status_is(200)
  ->json_is('/title', 'Hot House EP | music/is/for/losers')
  ->json_is('/link', 'https://musicisforlosers.bandcamp.com/album/hot-house-ep');

TODO: {
    local $TODO = 'Get artist and title direct from bandcamp page';

    $t->json_is('/artist', 'The Cyclist')
      ->json_is('/title',  'Hot House');
}

done_testing();
