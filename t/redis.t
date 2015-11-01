use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojo::Log;
use Mojo::Util qw(decode slurp);

# Fake redis port, to simulate a broken connection
$ENV{MOJO_REDIS_URL} = 'redis://localhost:9736';

# Logging to STDERR is redirected to buffer - you'll need to manually output
# $buffer if debugging an error.
my $buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDERR = $handle;
  my $log = Mojo::Log->new();

  my $t = Test::Mojo->new('MuSAPI');
  # Will hit API, which _should_ be available
  $t->get_ok('/api/v1/album/?p=deezer&q=Aphex Twin – Syro')
    ->status_is(200)
    ->json_is('/artist', 'Aphex Twin')
    ->json_is('/title',  'Syro')
    ->json_is('/id',     '8664043')
    ->json_like('/link', qr{https?://www.deezer.com/album/8664043});
}

my $content = decode 'UTF-8', $buffer;
like $content, qr/\[.*\] \[error\] Redis error whilst performing get operation: 'Connection refused'\n/, 'correct error - connection refused during get';
like $content, qr/\[.*\] \[error\] Redis error whilst performing set operation: 'Connection refused'\n/, 'correct error - connection refused during set';

warn "STDERR follows: ",$content,"\n";

done_testing();
