package MuSAPI::Model::Release;

use Moose;
use namespace::autoclean;

has 'artist' => (is => 'ro', isa => 'Str', default => '');
has 'title'  => (is => 'ro', isa => 'Str');
has 'link'   => (is => 'ro', isa => 'Str');
has 'id'     => (is => 'ro', isa => 'Str');

sub to_json {
    my $self = shift;

    return {
        artist => $self->artist,
        title  => $self->title,
        link   => $self->link,
        id     => $self->id,
    };
}

__PACKAGE__->meta->make_immutable;

1;
