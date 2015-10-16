package PlayLister::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';

sub search_deezer {
    my $self = shift;

    # an abbreviated deezer search result for:
    # http://api.deezer.com/search/album?q=Aphex Twin - Syro
    my $message = qq|{
  "data": [
    {
      "id": "8664043",
      "title": "Syro",
      "link": "http://www.deezer.com/album/8664043",
      "cover": "https://api.deezer.com/album/8664043/image",
      "cover_small": "https://cdns-images.deezer.com/images/cover/078e414889e91347a098f9d370997f2c/56x56-000000-80-0-0.jpg",
      "cover_medium": "https://cdns-images.deezer.com/images/cover/078e414889e91347a098f9d370997f2c/250x250-000000-80-0-0.jpg",
      "cover_big": "https://cdns-images.deezer.com/images/cover/078e414889e91347a098f9d370997f2c/500x500-000000-80-0-0.jpg",
      "genre_id": 106,
      "nb_tracks": 12,
      "record_type": "album",
      "tracklist": "https://api.deezer.com/album/8664043/tracks",
      "explicit_lyrics": false,
      "type": "album"
    }
  ],
  "total": 1
}|;

    $self->render(text => $message);
}

1;
