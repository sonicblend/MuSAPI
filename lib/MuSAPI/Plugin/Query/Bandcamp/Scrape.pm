package MuSAPI::Plugin::Query::Bandcamp::Scrape;
use Mojo::Base 'MuSAPI::Plugin::Query';
use Mojo::Util qw/url_escape dumper/;

# Inherits from 'MuSAPI::Plugin::Query'

# Given a URL, scrape a Bandcamp album page for the artist name and embedded
# player id

has 'provider_name' => 'Bandcamp_Scrape';

sub generate_url {
    my ($self, $c, $link) = @_;

    unless ($link =~ /bandcamp.com/) {
        $c->app->log->error("Expecting a bandcamp url, got: '$link'");
        return '';
    }

    return $link;
}

sub query_cb {
    my ($self, $c, $query, $cb, $tx) = @_;

    # Release details are found within a javascript array
    if (my ($data) = $tx->res->body =~ m/var EmbedData = \{(.*?)\}\;/s) {
        return $cb->({
            artist => $data =~ /artist: "(.*?)",?/,
            title  => $data =~ /album_title: "(.*?)",?/,
            link   => join ('', $data =~ /linkback: "(.*?)" \+ "(.*?)",/ ),
            id     => $data =~ /tralbum_param:.*?value: (\d+),?/,
        });
    }

    $c->app->log->error("Bandcamp page scrape fail", dumper $tx->res);
    return $cb->({ not_found => 1 });
}

1;
