package MuSAPI::Plugin::Cache;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Redis2;
use Mojo::Util qw/dumper/;

# Wrap the ua->get with a layer of cache. Requests are stored with a key name
# matching the url.
#
# If the cache is away, log an error message and request a live result.
# Use the MOJO_REDIS_URL environment variable to specify a Redis server, or
# default to localhost port :6379

my $redis = Mojo::Redis2->new;

sub register {
    my ($self, $app) = @_;

    # Helper deliberatly called cache and not Redis, should the need
    # arise to swap it for a different key-value store
    $app->helper(cache => sub { $self->query_redis(@_) });

    return;
}

sub query_redis {
    my ($self, $c, $url, $cb) = @_;

    unless ($url) {
        $c->app->log->error('redis helper expects a url');
        return $cb->();
    }

    $c->delay(
        sub {
            my ($delay) = @_;
            # search redis
            $c->app->log->debug('1. search redis. steps remaining ('.scalar @{$delay->remaining}.')');
            $redis->get($url, $delay->begin);
        },
        sub {
            my ($delay, $err, $message) = @_;

            $c->app->log->error("Redis error whilst performing get operation: '$err'") if $err;

            # hit!
            if ($message) {
                $c->app->log->info("cache hit for '$url'");
                $c->app->log->debug('2. cache hit - return with cached message');
                return $cb->($self->_fake_transaction($message));
            }

            # miss
            $c->app->log->info("cache missed for '$url'");
            $c->app->log->debug('2. cache missed. steps remaining ('.scalar @{$delay->remaining}.')');
            $delay->pass;
        },
        sub {
            my ($delay, $cb) = @_;

            # search live
            $c->app->log->debug('3. search. steps remaining ('.scalar @{$delay->remaining}.')');
            $c->ua->get($url, $delay->begin);
        },
        sub {
            my ($delay, $tx) = @_;

            $delay->data('tx' => $tx);

            if ($tx->res->code eq '200') {
                # save key-value in redis
                $c->app->log->debug('4. store response in redis. steps remaining ('.scalar @{$delay->remaining}.')');
                $redis->set($url => $tx->res->body, $delay->begin);
            }
            else {
                # output failure, but don't save to cache
                $c->app->log->error('Query unsuccessful: ', dumper $tx->res);
            }
        },
        sub {
            my ($delay, $err) = @_;

            # return transaction, regardless of whether it was stored in redis
            $c->app->log->error("Redis error whilst performing set operation: '$err'") if $err;
            $c->app->log->debug('5. return with message. steps remaining ('.scalar @{$delay->remaining}.')');
            return $cb->($delay->data('tx'));
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
