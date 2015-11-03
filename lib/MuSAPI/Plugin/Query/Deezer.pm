package MuSAPI::Plugin::Query::Deezer;
use Mojo::Base 'MuSAPI::Plugin::Query';
use Mojo::Util qw/url_escape/;

# Inherits from 'MuSAPI::Plugin::Query'

has 'provider_name' => 'Deezer';

sub query_cb {
    my ($self, $c, $query, $cb, $tx) = @_;

    if ($tx->res->json->{total} > 0) {
        my @json;
        foreach my $result ( @{ $tx->res->json->{data} } ) {
            push @json, {
                artist => $result->{artist}{name},
                title  => $result->{title},
                link   => $result->{link},
                id     => $result->{id},
            };
        };

        # return the first result only, the front-end isn't ready to
        # support multiple results
        return $cb->($json[0]);
    }

    return $cb->({ not_found => 1 });
}

sub generate_url {
    my ($self, $c, $query) = @_;

    # deezer won't return any results if emdash is used
    $query =~ s/–/-/g;

    return 'http://api.deezer.com/search/album'
           .'?q='.url_escape(lc($query));
}

1;
