package MuSAPI::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';

sub search {
    my $self = shift;

    my $query    = $self->param('q')
        or return $self->reply->not_found;
    my $provider = $self->param('p')
        or return $self->search_all($query);

    # limit search to a specific provider
    return $self->search_deezer($query)   if $provider =~ m/^deezer$/i;
    return $self->search_bandcamp($query) if $provider =~ m/^bandcamp$/i;

    return $self->reply->exception("unsupported provider value: '$provider'");
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
    $self->query_bandcamp($query, sub {
        $json->{bandcamp} = shift;
        $two->();
    });

    $self->render_later;
}

sub search_deezer {
    my ($self, $query) = @_;

    $self->query_deezer($query, sub {
        return $self->render(json => shift);
    });

    $self->render_later;
}

sub search_bandcamp {
    my ($self, $query) = @_;

    $self->query_bandcamp($query, sub {
        return $self->render(json => shift);
    });

    $self->render_later;
}

1;
