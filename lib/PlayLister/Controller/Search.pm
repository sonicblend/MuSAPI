package PlayLister::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';

sub search_deezer {
    my $self = shift;

    my $q = $self->param('album');
    # replace characters deezer doesn't like
    $q =~ s/–/-/g;

    my $ua = Mojo::UserAgent->new;
    my $message = $ua->get('http://api.deezer.com/search/album?q='.$q)->res->json;

    $self->render(json => $message);
}

1;
