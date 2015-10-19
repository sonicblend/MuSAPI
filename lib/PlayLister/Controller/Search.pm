package PlayLister::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';
use PlayLister::Model::Release;

sub search_deezer {
    my $self = shift;

    my $q = $self->param('album');
    # replace characters deezer doesn't like
    $q =~ s/–/-/g;

    # non-blocking request to get json for album
    my $message = $self->cache('http://api.deezer.com/search/album?q='.$q => sub {
        my ($ua, $mojo) = @_;

        if ($mojo->res->json->{total} > 0) {
            my $release = PlayLister::Model::Release->new(
                artist => $mojo->res->json->{data}[0]{artist}{name},
                title  => $mojo->res->json->{data}[0]{title},
                link   => $mojo->res->json->{data}[0]{link},
            );

            return $self->render(json => $release->to_json);
        }

        return $self->render(json => { not_found => 1 });
    });

    $self->render_later;
}

# As Bandcamp do not provide a public API, use Google to search Bandcamp:
# matching text in quotes and restricted to the bandcamp.com domain.
#
# The Google search API is limited to 100 queries per day so go via the web
# interface. Unfortunately this will break should Google change their html.

sub search_bandcamp {
    my $self = shift;

    my $q = $self->param('album');

    # Regexp to switch title and artist name around, as Bandcamp favour "Title
    # by Artist".
    #
    # Nowhere on bandcamp's shop pages do they use the "Artist - Title"
    # format, however if the regular expression fails (eg no dash included at
    # all) - default to using the text provided; unquoted. Excluding quotes
    # permits the search results to be less specific.
    $q =~ s/^
            (?<artist>.*?) # artist name
            \s*[-–]\s*     # dash or emdash surrounded by optional multiple spaces
            (?<title>.*)   # title
            $
           /"$+{title} by $+{artist}"/x;

    my $search = 'google.com/search?q=site:bandcamp.com%2Falbum+'.$q;
    my $res    = $self->cache($search => sub {
        my ($ua, $mojo) = @_;

        # Return if no results (search results appear at h3 level...)
        unless ($mojo->res->dom->find('h3 > a')->first) {
            return $self->render(json => { not_found => 1 });
        }

        my $title = $mojo->res->dom->find('h3 > a')->first->all_text;
        my $link  = $mojo->res->dom->find('cite')->first->all_text;
        # Remove all spaces from search link, caused by google adding the
        # <b>...</b> html tags when a search parameter matches the url, and
        # all_text() not being aware of the continuity.
        $link =~ s/\s//g;

        # TODO: go to bandcamp page for artist and title, as sometimes only
        # the release title and record label are available from google
        my $release = PlayLister::Model::Release->new(
            title  => $title,
            link   => $link,
        );

        return $self->render(json => $release->to_json);
    });

    $self->render_later;
}

1;
