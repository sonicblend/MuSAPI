use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MuSAPI');

subtest 'provider: deezer' => sub {
    $t->get_ok('/api/v1/album/?p=deezer&q=Aphex Twin – Syro')
      ->status_is(200)
#      ->json_is('/total', 1) # expect a single result - if not, data may not match
      ->json_is('/artist', 'Aphex Twin')
      ->json_is('/title',  'Syro')
      ->json_is('/id',     '8664043')
      ->json_like('/link', qr{https?://www.deezer.com/album/8664043});

    $t->get_ok('/api/v1/album/?p=deezer&q=Benjamin Clementine – At Least for Now')
      ->status_is(200)
#      ->json_is('/total', 1) # expect a single result - if not, data may not match
      ->json_is('/artist', 'Benjamin Clementine')
      ->json_is('/title',  'At Least For Now')
      ->json_is('/id',     '9787118')
      ->json_like('/link', qr{https?://www.deezer.com/album/9787118});
};

subtest 'provider: bandcamp' => sub {
    $t->get_ok('/api/v1/album/?p=bandcamp&q=Liquid Stranger - The Intergalactic Slapstick')
      ->status_is(200)
      ->json_like('/link', qr{https?://liquidstranger.bandcamp.com/album/the-intergalactic-slapstick})
      ->json_is('/artist', 'Liquid Stranger')
      ->json_is('/title',  'The Intergalactic Slapstick')
      ->json_is('/id',     '4283774662');

    $t->get_ok('/api/v1/album/?p=bandcamp&q=The Cyclist - Hot House')
      ->status_is(200)
      ->json_like('/link', qr{https?://musicisforlosers.bandcamp.com/album/hot-house-ep})
      ->json_is('/artist', 'The Cyclist')
      ->json_is('/title',  'Hot House EP')
      ->json_is('/id',     '3302283349');
};

subtest 'provider: bandcampweb' => sub {
    $t->get_ok('/api/v1/album/?p=bandcampweb&q=Liquid Stranger - The Intergalactic Slapstick')
      ->status_is(200)
      ->json_like('/link', qr{https?://liquidstranger.bandcamp.com/album/the-intergalactic-slapstick})
      ->json_is('/artist', 'Liquid Stranger')
      ->json_is('/title',  'The Intergalactic Slapstick')
      ->json_is('/id',     '4283774662');

    $t->get_ok('/api/v1/album/?p=bandcampweb&q=The Cyclist - Hot House')
      ->status_is(200)
      ->json_like('/link', qr{https?://musicisforlosers.bandcamp.com/album/hot-house-ep})
      ->json_is('/artist', 'The Cyclist')
      ->json_is('/title',  'Hot House EP')
      ->json_is('/id',     '3302283349');
};

subtest 'all' => sub {
    $t->get_ok('/api/v1/album/?q=Koan Sound - Forgotten Myths')
      ->status_is(200)
      ->json_is('/query', 'Koan Sound - Forgotten Myths')
      ->json_is('/deezer/title', 'Forgotten Myths')
      ->json_is('/deezer/artist', 'Koan Sound')
      ->json_like('/deezer/link', qr{https?://www.deezer.com/album/10716382})
      ->json_is('/deezer/id', '10716382')
      ->json_is('/bandcamp/title', 'Forgotten Myths')
      ->json_is('/bandcamp/artist', 'KOAN Sound')
      ->json_like('/bandcamp/link', qr{https?://koansound.bandcamp.com/album/forgotten-myths})
      ->json_is('/bandcamp/id', '922192078');
};

done_testing();
