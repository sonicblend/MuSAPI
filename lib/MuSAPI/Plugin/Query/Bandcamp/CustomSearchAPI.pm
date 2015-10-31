package MuSAPI::Plugin::Query::Bandcamp::CustomSearchAPI;
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

    $app->helper(query_bandcamp_cs => sub { $self->query_bandcamp_cs(@_) });

    return;
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
        my ($tx) = @_;

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
