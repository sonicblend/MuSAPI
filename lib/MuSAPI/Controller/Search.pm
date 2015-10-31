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
    $delay->steps(sub {
        return $self->render(json => $json);
    });

    # run queries concurrently
    $self->query_deezer($query, sub {
        $json->{deezer} = shift;
        $one->();
    });
    $self->query_bandcamp_cs($query, sub {
        $json->{bandcamp} = shift;
        $two->();
    });

    $self->render_later;
}

sub search_provider {
    my ($self, $query, $provider) = @_;

    # limit search to specific provider
    $self->render_later;
    my $cb = sub {
        return $self->render(json => shift);
    };
    return $self->query_bandcamp_cs($query, $cb) if $provider =~ m/^bandcamp$/i;
    return $self->query_deezer($query, $cb) if $provider =~ m/^deezer$/i;

    return $self->reply->exception("unsupported provider value: '$provider'");
}

1;
