package MuSAPI::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';

sub search_all {
    my $self = shift;

    # json reference, concurrently populated by query handlers
    my $json = {
        query => $self->param('album'),
    };

    my $delay = Mojo::IOLoop::Delay->new;
    my $one = $delay->begin();
    my $two = $delay->begin();

    # json rendered when all queries complete
    $delay->steps(sub {
        return $self->render(json => $json);
    });

    # run queries concurrently
    $self->query_deezer($self->param('album'), sub {
        $json->{deezer} = shift;
        $one->();
    });
    $self->query_bandcamp($self->param('album'), sub {
        $json->{bandcamp} = shift;
        $two->();
    });

    $self->render_later;
}

sub search_deezer {
    my $self = shift;

    $self->query_deezer($self->param('album'), sub {
        return $self->render(json => shift);
    });

    $self->render_later;
}

sub search_bandcamp {
    my $self = shift;

    $self->query_bandcamp($self->param('album'), sub {
        return $self->render(json => shift);
    });

    $self->render_later;
}

1;
