package MuSAPI;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->plugin('MuSAPI::Plugin::Cache');
    $self->plugin('MuSAPI::Plugin::Query::Bandcamp::Scrape');
    $self->plugin('MuSAPI::Plugin::Query::CustomSearch::Bandcamp');
    $self->plugin('MuSAPI::Plugin::Query::GoogleWeb::Bandcamp');
    $self->plugin('MuSAPI::Plugin::Query::Deezer');

    # Router
    my $r = $self->routes;

    $r->get('/api/v1/album/')->to('search#search');
}

1;
