package MuSAPI::Plugin::Query::GoogleWeb::Bandcamp;
use Mojo::Base 'MuSAPI::Plugin::Query';
use Mojo::Util qw/url_escape dumper/;

# Inherits from 'MuSAPI::Plugin::Query'

# Warning:
# This will break should Google / Bandcamp change their html, also Google
# sometimes denies robots.

has 'provider_name' => 'GoogleWeb_Bandcamp';

sub init {
    my ($self, $app) = @_;

    # google redirects hits to their search page to a closer server.
    $app->ua->max_redirects(2); # was 0
}

sub generate_url {
    my ($self, $c, $query) = @_;

    # If original query was "artist - title", try rearrange to
    # "title by artist", used by bandcamp throughout their album page.
    $query =~ s/^
                (?<artist>.*?) # artist name
                \s*[-–]\s*     # dash or emdash surrounded by optional multiple spaces
                (?<title>.*)   # title
                $
               /"$+{title} by $+{artist}"/x;

    return 'http://google.com/search'
           .'?q=site:bandcamp.com%2Falbum'
           .'+'.url_escape(lc($query));
}

sub query_cb {
    my ($self, $c, $query, $cb, $tx) = @_;

    # Each result has an h3 element
    unless ($tx->res->dom->find('h3 > a')->first) {
        return $cb->({ not_found => 1 });
    }

    my $title = $tx->res->dom->find('h3 > a')->first->all_text;
    my $link  = $tx->res->dom->find('cite')->first->all_text;
    # Google adds <b> tags to highlight matching keywords, which sometimes
    # occur in the url. all_text() removes them, strip any remaining spaces:
    $link =~ s/\s//g;
    $link =~ s/^https/http/;

    $cb->({
        title => $title,
        link  => $link,
    });
}

1;
