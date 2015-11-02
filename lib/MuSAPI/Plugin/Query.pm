package MuSAPI::Plugin::Query;
use Mojo::Base 'Mojolicious::Plugin';

# Parent Query class - children must specify:
has 'provider_name';

sub generate_url { die 'implement generate_url()' }
sub query_cb     { die 'implement query_cb()' }

# Wrapper methods

sub register {
    my ($self, $app) = @_;

    # call optional initialisation method
    $self->init($app) if $self->can('init');

    die 'implement provider_name' unless defined $self->provider_name;

    # if provider_name was 'Deezer', helper name would be 'query_deezer'
    my $helper_name = 'query_'.lc($self->provider_name);

    $app->helper($helper_name => sub { $self->query(@_) });

    return;
}

sub query {
    my ($self, $c, $query, $cb) = @_;

    my $url = $self->generate_url($query);

    $c->cache($url => sub {
        my ($tx) = @_;

        # dont process result if the query wasn't a success
        return $self->_unexpected_status($c, $tx, $cb) if $tx->res->code != 200;

        # call the child's query_cb
        return $self->query_cb($c, $query, $cb, $tx);
    });
}

sub _unexpected_status {
    my ($self, $c, $tx, $cb) = @_;

    $c->app->log->error('Unexpected status "'.$tx->res->code.'" from '
                        .$self->provider_name.': "'.$tx->res->body.'"');

    return $cb->({server_error => 1});
}

1;
