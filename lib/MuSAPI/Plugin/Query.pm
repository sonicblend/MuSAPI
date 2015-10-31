package MuSAPI::Plugin::Query;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util qw/url_escape/;

my $bandcamp_cs_cx;
my $google_api_key;

sub register {
    my ($self, $app) = @_;

    $bandcamp_cs_cx = $ENV{'BANDCAMP_CS_CX'}
        or die 'BANDCAMP_CS_CX env variable not set';
    $google_api_key = $ENV{'GOOGLE_API_KEY'}
        or die 'GOOGLE_API_KEY env variable not set';

    $app->helper(query_deezer   => sub { $self->query_deezer(@_) });
    $app->helper(query_bandcamp => sub { $self->query_bandcamp_cs(@_) });

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
        my ($ua, $tx) = @_;

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

# As Bandcamp do not provide a public API, use Google to search Bandcamp:
# matching text in quotes and restricted to the bandcamp.com domain.
#
# The Google search API is limited to 100 queries per day so go via the web
# interface. Unfortunately this will break should Google change their html.

sub query_bandcamp_scrape {
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
                my ($ua, $tx) = @_;

                # Return if no results (search results appear at h3 level...)
                unless ($tx->res->dom->find('h3 > a')->first) {
                    return $cb->({ not_found => 1 });
                }

                my $title = $tx->res->dom->find('h3 > a')->first->all_text;
                my $link  = $tx->res->dom->find('cite')->first->all_text;
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
                my ($ua, $tx) = @_;

                # Release details are found within a javascript array
                if (my ($data) = $tx->res->body =~ m/var EmbedData = \{(.*?)\}\;/s) {

                    return $cb->({
                        artist => $data =~ /artist: "(.*?)",?/,
                        title  => $data =~ /album_title: "(.*?)",?/,
                        link   => $link,
                        id     => $data =~ /tralbum_param:.*?value: (\d+),?/,
                    });
                }

                warn "Bandcamp page scrape fail";
                return $cb->({ not_found => 1 });
            });
        },
    );
}

# Bandcamp do not provide a public API so use a Google Custom Search to
# search Bandcamp, with filter restricting results to the bandcamp.com domain.
#
# The RESTful API free limit is 100 queries per day, then - if billing is
# enabled they charge $5 / 10,000 queries. At time of writing, Bing and Yahoo
# had limited coverage of Bandcamp.
#
# Hitting the query limit is not currently supported... It would be best to
# avoid caching failed results.
#
# Query paramater list:
# https://developers.google.com/custom-search/json-api/v1/reference/cse/list
#
# Interactive API explorer:
# https://developers.google.com/apis-explorer/#p/customsearch/v1/search.cse.list
#
# Partial response filters: (the &fields parameter)
# https://developers.google.com/custom-search/json-api/v1/performance#partial

sub query_bandcamp_cs {
    my ($self, $c, $query, $cb) = @_;

    # Split search terms and quote as "artist name" "title"
    $query =~ s/^
                (?<artist>.*?) # artist name
                \s*[-–]\s*     # dash or emdash surrounded by optional multiple spaces
                (?<title>.*)   # title
                $
               /"$+{artist}" "$+{title}"/x;

    my $url = 'https://www.googleapis.com/customsearch/v1'
             .'?num=1'
             .'&fields=items(link,pagemap(musicalbum,metatags))'
             .'&cx='.  $bandcamp_cs_cx
             .'&key='. $google_api_key
             .'&q='.   url_escape(lc $query);

    $c->cache($url => sub {
        my ($ua, $tx) = @_;

        if ($tx->res->json and @{$tx->res->json->{items}}) {
            my $first = $tx->res->json->{items}[0];

            # awesome, bandcamp provides schema.org and opengraph metadata
            return $cb->({
                artist => $first->{pagemap}->{musicalbum}[0]->{byartist},
                title  => $first->{pagemap}->{musicalbum}[0]->{name},
                link   => $first->{link},
                # only the numerical id segment
                id     => $first->{pagemap}->{metatags}[0]->{'og:video'} =~ /album=(\d+)/,
            });
        }

        return $cb->({ not_found => 1 });
    });
}

1;
