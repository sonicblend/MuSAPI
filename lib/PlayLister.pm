package PlayLister;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Router
    my $r = $self->routes;

    $r->get('/search/deezer/(:album)')->to('search#search_deezer');
}

1;
