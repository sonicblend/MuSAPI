package MuSAPI::Plugin::Query::Deezer;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/url_escape/;

sub register {
    my ($self, $app) = @_;

    $app->helper(query_deezer => sub { $self->query_deezer(@_) });

    return;
}

sub query_deezer {
    my ($self, $c, $query, $cb) = @_;

    my $url = $self->generate_url($query);

    $c->cache($url => sub {
        my ($tx) = @_;

        # dont process result if the query wasn't a success
        return $self->unexpected_status($c, $tx, $cb) if $tx->res->code != 200;

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
    });
}

sub generate_url {
    my ($self, $query) = @_;

    # replace characters deezer doesn't like
    $query =~ s/–/-/g;

    return 'http://api.deezer.com/search/album'
           .'?q='.url_escape(lc($query));
}

sub unexpected_status {
    my ($self, $c, $tx, $cb) = @_;

    $c->app->log->error('Unexpected status "'.$tx->res->code.'" from Deezer: "'.$tx->res->body.'"');
    return $cb->({server_error => 1});
}

1;
