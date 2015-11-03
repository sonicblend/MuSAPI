package MuSAPI::Plugin::Query::GoogleWeb::Bandcamp;
use Mojo::Base 'MuSAPI::Plugin::Query';
use Mojo::Util qw/url_escape dumper/;

# Inherits from 'MuSAPI::Plugin::Query'

has 'provider_name' => 'GoogleWeb_Bandcamp';

# WARNING:
#
# If performing < 100 queries a day, prefer:
# MuSAPI::Plugin::Query::CustomSearch::Bandcamp
#
# It's less likely to break than this, also if Google suspects a robot has
# been using the web-search, for example I suspect if the web server is
# running on an IP range that doesn't normally perform web queries, they begin
# to ask CAPCHA questions...
#

sub init {
    my ($self, $app) = @_;

    # increase max_redirects from 0 as google redirects hits to their search
    # page e.g. to a closer tld server
    $app->ua->max_redirects(2);
}

# Bandcamp do not provide a public API, and Google's custom search API is
# restricted to 100 free queries a day, so:
#
# 1. scrape Google's web search results for the Bandcamp page
# 2. scrape the Bandcamp page for the artist name, and embedded player id
#
# Unfortunately this will break should Google / Bandcamp change their html.

sub query_cb {
    my ($self, $c, $query, $cb, $tx) = @_;

    # Return if Google presents no results (search results appear at h3 level...)
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

    # Use the link to scrape Bandcamp, to get additional release details
    $cb->({
        title => $title,
        link  => $link,
    });
}

sub generate_url {
    my ($self, $query) = @_;

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

    return 'google.com/search'
           .'?q=site:bandcamp.com%2Falbum'
           .'+'.url_escape(lc($query));
}

1;
