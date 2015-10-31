package MuSAPI;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Add helper 'cache': wraps ua->get with a query to the cache first, to
    # reduce repeated traffic
    $self->plugin('MuSAPI::Plugin::Cache');
    $self->plugin('MuSAPI::Plugin::Query::Bandcamp::CustomSearchAPI');
    #$self->plugin('MuSAPI::Plugin::Query::Bandcamp::Scrape');
    $self->plugin('MuSAPI::Plugin::Query::Deezer');

    # Router
    my $r = $self->routes;

    $r->get('/api/v1/album/')->to('search#search');
}

1;
