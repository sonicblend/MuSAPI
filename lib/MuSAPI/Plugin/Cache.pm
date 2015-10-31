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
                say "cache hit for '$query'";
#                warn "2. cache hit - return with cached message\n";
                return $cb->($c->ua, $self->_fake_transaction($message));
            }

            # miss
            say "cache missed for '$query'";
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
            return $cb->($c->ua, $self->_fake_transaction($message));
        },
    );
}

# Fake a Mojo::Transaction::HTTP so that the callback can use the
# Mojo::Message JSON / DOM inspection tools

sub _fake_transaction {
    my ($self, $message) = @_;

    my $tx = Mojo::Transaction::HTTP->new;
    $tx->res->code(200);
    $tx->res->body($message);

    return $tx;
}

1;
