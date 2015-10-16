use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('PlayLister');
$t->get_ok('/search/deezer/Aphex Twin – Syro')
  ->status_is(200)
  ->content_like(qr|http://www.deezer.com/album/8664043|);

TODO: {
    local $TODO = 'Deezer API call not yet implemented';

    $t->get_ok('/search/deezer/Benjamin Clementine – At Least for Now')
      ->status_is(200)
      ->content_like(qr|http://www.deezer.com/album/9787118|);
}

done_testing();
