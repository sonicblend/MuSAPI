package PlayLister::Plugin::Cache;
use Mojo::Base 'Mojolicious::Plugin';

use Moose;
use Mojo::Redis2;

# Mojo::Redis2->new() is not called unless lay arg is specified, unsure why?
has 'cache' => (is => 'ro', isa => 'Mojo::Redis2', default => sub { Mojo::Redis2->new; }, lazy => 1);

sub register {
    my ($self, $app) = @_;

    # helper deliberatly called cache and not redis, should the need
    # arise to swap it out for another key-value store
    $app->helper(cache => sub { $self->redis(@_) });

    return;
}

# TODO: Handle failures gracefully
# 1a. Redis DB away
# 1b. $query parameter missing

sub redis {
    my ($self, $c, $query, $cb) = @_;

    unless ($query) {
        warn "redis helper expects a query";
        return $cb->();
    }

    $c->delay(
        sub {
            my ($delay) = @_;
            warn "A. search redis for key: '$query'. steps remaining (", scalar @{$delay->remaining}, ")\n";

            $self->cache->get($query, $delay->begin);
        },
        sub {
            my ($delay, $err, $message) = @_;

            # found key in redis
            if ($message) {
                warn "B1. got a key from redis. steps remaining (", scalar @{$delay->remaining}, ")\n";

                # fake a Mojo::Transaction::HTTP so the callback args match
                # that of $self->ua->get()
                my $tx = Mojo::Transaction::HTTP->new;
                $tx->res->code(200);
                $tx->res->body($message);

                return $cb->($c->ua, $tx);
            }

            warn "B2. no key found in redis - search. steps remaining (", scalar @{$delay->remaining}, ")\n";
            $c->ua->get($query => sub {
                my ($ua, $mojo) = @_;

                warn "B3. response fetched. steps remaining (", scalar @{$delay->remaining}, ")\n";
                $c->delay(
                    sub {
                        my ($delay) = @_;

                        warn "C1. store response in redis. steps remaining (", scalar @{$delay->remaining}, ")\n";
                        $self->cache->set($query => $mojo->res->body, $delay->begin);
                    },
                    sub {
                        my ($delay, $err, $message) = @_;

                        warn "C2. callback. steps remaining (", scalar @{$delay->remaining}, ")\n";
                        return $cb->($ua, $mojo);
                    }
                );
            });
        },
    );
}

1;
