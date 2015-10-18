package PlayLister;
use Mojo::Base 'Mojolicious';

use Moose;
use Mojo::Redis2;

# Mojo::Redis2->new() is not called unless lay arg is specified, unsure why?
has 'redis' => (is => 'ro', isa => 'Mojo::Redis2', default => sub { Mojo::Redis2->new; }, lazy => 1);

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->helper(redis => sub {
        my ($c, $query, $cb) = @_;

        unless ($query) {
            warn "redis helper expects a query";
            # TODO: call back...
            return;
        }

        $self->delay(
            sub {
                my ($delay) = @_;
                warn "A. search redis for key: '$query'. steps remaining (", scalar @{$delay->remaining}, ")\n";

                $self->redis->get($query, $delay->begin);
            },
            sub {
                my ($delay, $err, $message) = @_;

                # found key in redis
                if ($message) {
                    warn "B1. got a key from redis. steps remaining (", scalar @{$delay->remaining}, ")\n";

                    # fake a Mojo::Transaction::HTTP, not ideal!
                    my $tx = Mojo::Transaction::HTTP->new;
                    $tx->res->code(200);
                    $tx->res->body($message);

                    return $cb->($self->ua, $tx);
                }

                warn "B2. no key found in redis - search. steps remaining (", scalar @{$delay->remaining}, ")\n";
                $self->ua->get($query => sub {
                    my ($ua, $mojo) = @_;

                    warn "B3. returned. steps remaining (", scalar @{$delay->remaining}, ")\n";
                    $self->delay(
                        sub {
                            my ($delay) = @_;

                            warn "C1. store key in redis. steps remaining (", scalar @{$delay->remaining}, ")\n";
                            $self->redis->set($query => $mojo->res->body, $delay->begin);
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
    });

    # increase max_redirects from 0 as google redirects hits to their search
    # page e.g. to a closer tld server
    $self->ua->max_redirects(2);

    # Router
    my $r = $self->routes;

    $r->get('/search/deezer/(:album)'  )->to('search#search_deezer');
    $r->get('/search/bandcamp/(:album)')->to('search#search_bandcamp');
}

1;
