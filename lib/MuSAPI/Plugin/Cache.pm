package MuSAPI::Plugin::Cache;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Redis2;

# use the MOJO_REDIS_URL environment variable, or defaults to port :6379
my $redis = Mojo::Redis2->new;

sub register {
    my ($self, $app) = @_;

    # helper deliberatly called cache and not redis, should the need
    # arise to swap it out for another key-value store
    $app->helper(cache => sub { $self->query_redis(@_) });

    return;
}

sub query_redis {
    my ($self, $c, $query, $cb) = @_;

    unless ($query) {
        warn "redis helper expects a query";
        return $cb->();
    }

    $c->delay(
        sub {
            my ($delay) = @_;
#            warn "1. search redis. steps remaining (", scalar @{$delay->remaining}, ")\n";

            # search redis
            $redis->get($query, $delay->begin);
        },
        sub {
            my ($delay, $err, $message) = @_;

            # hit!
            if ($message) {
                warn "cache hit for '$query'\n";
#                warn "2. cache hit - return with cached message\n";

                # fake a Mojo::Transaction::HTTP so the callback args match
                # that of $self->ua->get()
                my $tx = Mojo::Transaction::HTTP->new;
                $tx->res->code(200);
                $tx->res->body($message);

                return $cb->($c->ua, $tx);
            }

            # miss
            warn "cache missed for '$query'\n";
#            warn "2. cache missed. steps remaining (", scalar @{$delay->remaining}, ")\n";
            $delay->pass;
        },
        sub {
            my ($delay, $cb) = @_;

            # search live
#            warn "3. search. steps remaining (", scalar @{$delay->remaining}, ")\n";
            $c->ua->get($query, $delay->begin);
        },
        sub {
            my ($delay, $tx) = @_;

            # save key-value in redis
#            warn "4. store response in redis. steps remaining (", scalar @{$delay->remaining}, ")\n";
            $redis->set($query => $tx->res->body);

            $delay->pass($tx->res->body);
        },
        sub {
            my ($delay, $message, $err) = @_;

#            warn "5. return with message. steps remaining (", scalar @{$delay->remaining}, ")\n";

            # fake a Mojo::Transaction::HTTP so the callback args match
            # that of $self->ua->get()
            my $tx = Mojo::Transaction::HTTP->new;
            $tx->res->code(200);
            $tx->res->body($message);

            return $cb->($c->ua, $tx);
        },
    );
}

1;
