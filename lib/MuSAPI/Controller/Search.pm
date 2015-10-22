package MuSAPI::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';

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
