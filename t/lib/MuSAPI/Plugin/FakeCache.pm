package MuSAPI::Plugin::FakeCache;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $test_results) = @_;

    $app->helper(cache => sub {
        my ($self, $url, $cb) = @_;

        unless ($url) {
            $app->log->error('redis helper expects a url');
            return $cb->();
        }

        # Shift a test_result, fake a transaction and return it in the callback
        my $result = shift @{$test_results};
        warn "no results to shift!" unless $result;

        my $tx = Mojo::Transaction::HTTP->new;
        $tx->res->code($result->{code});
        $tx->res->body($result->{body});
        return $cb->($tx);
    });
}

1;
