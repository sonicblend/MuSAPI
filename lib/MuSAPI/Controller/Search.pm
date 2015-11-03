package MuSAPI::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';

sub search {
    my $self = shift;

    my $query    = $self->param('q') or return $self->reply->not_found;

    # search all providers if p not specified
    my $provider = $self->param('p') or return $self->search_all($query);

    # restrict search to specific provider
    return $self->search_provider($query, $provider);
}

sub search_all {
    my ($self, $query) = @_;

    # json reference, concurrently populated by query handlers
    my $json = {
        query => $query,
    };

    my $delay = Mojo::IOLoop::Delay->new;
    my $one = $delay->begin();
    my $two = $delay->begin();

    # json rendered when all queries complete
    $delay->steps(sub { return $self->_render_result($json) });

    # run queries concurrently
    $self->query_deezer($query, sub {
        $json->{deezer} = shift;
        $one->();
    });
    $self->query_customsearch_bandcamp($query, sub {
        $json->{bandcamp} = shift;
        $two->();
    });

    $self->render_later;
}

sub search_provider {
    my ($self, $query, $provider) = @_;

    # limit search to specific provider
    $self->render_later;
    my $cb = sub { return $self->_render_result(shift) };

    return $self->query_customsearch_bandcamp($query, $cb) if $provider =~ m/^bandcamp$/i;
    return $self->query_deezer($query, $cb) if $provider =~ m/^deezer$/i;

    # operations which require chaining multiple queries
    return $self->search_bc_web($query, $cb) if $provider =~ m/^bandcampweb$/i;

    return $self->reply->exception("unsupported provider value: '$provider'");
}

# chain two queries:
# 1. scrape google web for bandcamp page
# 2. scrape bandcamp page for metadata

sub search_bc_web {
    my ($self, $query, $cb2) = @_;

    $self->render_later;

    my $cb1 = sub {
        my $json = shift;
        if (exists $json->{link}) {
            return $self->query_bandcamp_scrape($json->{link}, $cb2);
        }
        return $self->_render_result(shift);
    };
    return $self->query_googleweb_bandcamp($query, $cb1);
}

sub _render_result {
    my ($self, $json) = @_;
    return $self->render(json => {}, status => 500) if exists $json->{server_error};
    return $self->render(json => $json);
}

1;
