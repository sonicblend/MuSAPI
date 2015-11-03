package MuSAPI::Plugin::Query::CustomSearch::Bandcamp;
use Mojo::Base 'MuSAPI::Plugin::Query';
use Mojo::Util qw/url_escape/;

# Inherits from 'MuSAPI::Plugin::Query'

has 'provider_name' => 'CustomSearch_Bandcamp';

my $bandcamp_cs_cx;
my $google_api_key;

sub init {
    my ($self, $app) = @_;

    $bandcamp_cs_cx = $ENV{'BANDCAMP_CS_CX'}
        or die 'BANDCAMP_CS_CX env variable not set';
    $google_api_key = $ENV{'GOOGLE_API_KEY'}
        or die 'GOOGLE_API_KEY env variable not set';
}

# Bandcamp do not provide a public API so use a Google Custom Search to
# search Bandcamp, with filter restricting results to the bandcamp.com domain.
#
# See wiki for Custom Search documentation links:
# https://github.com/sonicblend/MuSAPI/wiki/Bandcamp-via-Google-Custom-Search

sub query_cb {
    my ($self, $c, $query, $cb, $tx) = @_;

    if (exists $tx->res->json->{items} and @{$tx->res->json->{items}}) {
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
}

sub generate_url {
    my ($self, $c, $query) = @_;

    # Split search terms and quote as "artist name" "title"
    $query =~ s/^
                (?<artist>.*?) # artist name
                \s*[-–]\s*     # dash or emdash surrounded by optional multiple spaces
                (?<title>.*)   # title
                $
               /"$+{artist}" "$+{title}"/x;

    return 'https://www.googleapis.com/customsearch/v1'
           .'?num=1'
           .'&fields=items(link,pagemap(musicalbum,metatags))'
           .'&cx='.  $bandcamp_cs_cx
           .'&key='. $google_api_key
           .'&q='.   url_escape(lc($query));
}

1;
