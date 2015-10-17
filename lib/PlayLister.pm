package PlayLister;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # increase max_redirects from 0 as google redirects hits to their search
    # page e.g. to a closer tld server
    $self->ua->max_redirects(2);

    # Router
    my $r = $self->routes;

    $r->get('/search/deezer/(:album)'  )->to('search#search_deezer');
    $r->get('/search/bandcamp/(:album)')->to('search#search_bandcamp');
}

1;
