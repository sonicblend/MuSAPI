package MuSAPI::Plugin::Query;
use Mojo::Base 'Mojolicious::Plugin';

use MuSAPI::Model::Release;

sub register {
    my ($self, $app) = @_;

    $app->helper(query_deezer   => sub { $self->query_deezer(@_) });
    $app->helper(query_bandcamp => sub { $self->query_bandcamp(@_) });

    return;
}

# Query helper overview:
#
# 1. receive a query
# 2. perform a search
# 3. pass standard json to the callback

sub query_deezer {
    my ($self, $c, $query, $cb) = @_;

    # replace characters deezer doesn't like
    $query =~ s/–/-/g;
    $query = 'http://api.deezer.com/search/album?q='.$query;

    # non-blocking request to get json for album
    $c->cache($query => sub {
        my ($ua, $mojo) = @_;

        if ($mojo->res->json->{total} > 0) {

            my @json;
            foreach my $result ( @{ $mojo->res->json->{data} } ) {
                push @json, MuSAPI::Model::Release->new(
                    artist => $result->{artist}{name},
                    title  => $result->{title},
                    link   => $result->{link},
                    id     => $result->{id},
                )->to_json;
            };

            # return the first result only, the front-end isn't ready to
            # support multiple results
            return $cb->($json[0]);
        }

        return $cb->({ not_found => 1 });
    });
}

# As Bandcamp do not provide a public API, use Google to search Bandcamp:
# matching text in quotes and restricted to the bandcamp.com domain.
#
# The Google search API is limited to 100 queries per day so go via the web
# interface. Unfortunately this will break should Google change their html.

sub query_bandcamp {
    my ($self, $c, $query, $cb) = @_;

    # Regexp to switch title and artist name around, as Bandcamp favour "Title
    # by Artist".
    #
    # Nowhere on bandcamp's shop pages do they use the "Artist - Title"
    # format, however if the regular expression fails (eg no dash included at
    # all) - default to using the text provided; unquoted. Excluding quotes
    # permits the search results to be less specific.
    $query =~ s/^
                (?<artist>.*?) # artist name
                \s*[-–]\s*     # dash or emdash surrounded by optional multiple spaces
                (?<title>.*)   # title
                $
               /"$+{title} by $+{artist}"/x;
    $query = 'google.com/search?q=site:bandcamp.com%2Falbum+'.$query;

    $c->delay(
        # Scrape Google to find first result
        sub {
            my $delay = shift;
            my $end   = $delay->begin();

            $c->cache($query => sub {
                my ($ua, $mojo) = @_;

                # Return if no results (search results appear at h3 level...)
                unless ($mojo->res->dom->find('h3 > a')->first) {
                    return $cb->({ not_found => 1 });
                }

                my $title = $mojo->res->dom->find('h3 > a')->first->all_text;
                my $link  = $mojo->res->dom->find('cite')->first->all_text;
                # Remove all spaces from search link, caused by google adding the
                # <b>...</b> html tags when a search parameter matches the url, and
                # all_text() not being aware of the continuity.
                $link =~ s/\s//g;
                # http is fine
                $link =~ s/^https/http/;

                # pass to next step
                $delay->pass($link);
                $end->();
            });
        },
        # Scrape Bandcamp to get additional release details
        sub {
            my ($delay, $link) = @_;

            $c->cache($link => sub {
                my ($ua, $mojo) = @_;

                # Release details are found within a javascript array
                if (my ($data) = $mojo->res->body =~ m/var EmbedData = \{(.*?)\}\;/s) {

                    my $json = MuSAPI::Model::Release->new(
                        artist => $data =~ /artist: "(.*?)",?/,
                        title  => $data =~ /album_title: "(.*?)",?/,
                        link   => $link,
                        id     => $data =~ /tralbum_param:.*?value: (\d+),?/,
                    )->to_json;

                    return $cb->($json);
                }

                warn "Bandcamp page scrape fail";
                return $cb->({ not_found => 1 });
            });
        },
    );
}

1;
