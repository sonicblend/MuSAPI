package PlayLister::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';

sub search_deezer {
    my $self = shift;

    my $q = $self->param('album');
    # replace characters deezer doesn't like
    $q =~ s/–/-/g;

    # non-blocking request to get json for album
    my $message = $self->ua->get('http://api.deezer.com/search/album?q='.$q => sub {
        my ($ua, $mojo) = @_;
        $self->render(json => $mojo->res->json);
    });

    $self->render_later;
}

1;
