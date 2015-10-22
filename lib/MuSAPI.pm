package MuSAPI;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Add helper 'cache': wraps ua->get with a query to the cache first, to
    # reduce repeated traffic
    $self->plugin('MuSAPI::Plugin::Cache');
    $self->plugin('MuSAPI::Plugin::Query');

    # increase max_redirects from 0 as google redirects hits to their search
    # page e.g. to a closer tld server
    $self->ua->max_redirects(2);

    # Router
    my $r = $self->routes;

    $r->get('/search/deezer/(:album)'  )->to('search#search_deezer');
    $r->get('/search/bandcamp/(:album)')->to('search#search_bandcamp');
}

1;
