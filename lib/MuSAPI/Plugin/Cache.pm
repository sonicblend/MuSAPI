package MuSAPI::Plugin::Cache;
use Mojo::Base 'Mojolicious::Plugin';

use Moose;
use Mojo::Redis2;
use namespace::autoclean;

has 'cache' => (is => 'rw', isa => 'Mojo::Redis2');

sub register {
    my ($self, $app) = @_;

    $self->cache( Mojo::Redis2->new(
        url => $app->config->{'redis_url'} || 'redis://localhost:6379'
    ));

    # helper deliberatly called cache and not redis, should the need
    # arise to swap it out for another key-value store
    $app->helper(cache => sub { $self->redis(@_) });

    return;
}

sub redis {
    my ($self, $c, $query, $cb) = @_;

    unless ($query) {
        warn "redis helper expects a query";
        return $cb->();
    }

    $c->delay(
        sub {
            my ($delay) = @_;
#            warn "A. search redis for key: '$query'. steps remaining (", scalar @{$delay->remaining}, ")\n";

            $self->cache->get($query, $delay->begin);
        },
        sub {
            my ($delay, $err, $message) = @_;

            # found key in cache
            if ($message) {
                warn "cache success: '$query'\n";
#                warn "B1. got a key from redis. steps remaining (", scalar @{$delay->remaining}, ")\n";

                # fake a Mojo::Transaction::HTTP so the callback args match
                # that of $self->ua->get()
                my $tx = Mojo::Transaction::HTTP->new;
                $tx->res->code(200);
                $tx->res->body($message);

                return $cb->($c->ua, $tx);
            }

            # key not previously cached, search for it
#            warn "B2. no key found in redis - search. steps remaining (", scalar @{$delay->remaining}, ")\n";
            $c->ua->get($query => sub {
                my ($ua, $mojo) = @_;

                # save key-value in cache
#                warn "B3. response fetched. steps remaining (", scalar @{$delay->remaining}, ")\n";
                $c->delay(
                    sub {
                        my ($delay) = @_;

#                        warn "C1. store response in redis. steps remaining (", scalar @{$delay->remaining}, ")\n";
                        $self->cache->set($query => $mojo->res->body, $delay->begin);
                    },
                    sub {
                        my ($delay, $err, $message) = @_;

#                        warn "C2. callback. steps remaining (", scalar @{$delay->remaining}, ")\n";
                        return $cb->($ua, $mojo);
                    }
                );
            });
        },
    );
}

# Moose constructor disabled, as Mojolicious::Plugin has a constructor
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
