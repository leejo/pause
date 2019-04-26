use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::PAUSE::Web;
use HTTP::Status qw/:constants/;
use JSON::PP;
use Test::Deep;
use utf8;

Test::PAUSE::Web->setup;

my $common_qparams = "response_type=code&redirect_uri=https://foo.com";
my $test = Test::PAUSE::Web->tests_for('user');
my ($path, $user) = @$test;
my $t = Test::PAUSE::Web->new(user => $user);

# we're testing the redirect content, so disable the user agent's
# automatic handling of them so we can inspect the redirect
$t->{mech}->requests_redirectable( [] );

subtest 'unknown client' => sub {

  my $res = $t->get(
    "/pause/authenquery/oauth/authorize"
    . "?client_id=bad_client_id"
    . "&$common_qparams"
  );

  is(
    $res->header( 'location' ),
    'https://foo.com?error=unauthorized_client',
    'redirect location has error'
  );
};

my $access_token;

subtest 'known client' => sub {

  my $res = $t->get(
    "/pause/authenquery/oauth/authorize"
    . "?client_id=ACT"
    . "&$common_qparams"
  );

  like(
    $res->header( 'location' ),
    qr!https://foo\.com\?code=(.*?)!,
    'redirect location has code'
  );

  my $auth_code = ( split( 'code=',$res->header( 'location' ) ) )[1];

  $res = $t->post_ok(
    "/pause/oauth/access_token",
    {
      code => $auth_code,
      client_id => 'ACT',
      client_secret => 'some_strong_client_secret',
      grant_type => 'authorization_code',
      redirect_uri => 'https://foo.com',
    }
  );

  cmp_deeply(
    my $json = decode_json( $res->content ),
    {
      access_token => re( '.+' ),
      refresh_token => re( '.+' ),
      expires_in => 86400,
      token_type => 'Bearer',
    },
    'request for access token'
  );

  $access_token = $json->{access_token};
};

subtest 'get user info' => sub {

  $t->{mech}->requests_redirectable( [] );
  my $res = $t->get(
    "/pause/api/me",
    Authorization => "Bearer $access_token",
  );

  cmp_deeply(
    my $json = decode_json( $res->content ),
    {
      pause_id => 'TESTUSER',
      email    => 'pause_admin@localhost.localdomain',
      homepage => undef,
    },
    'JSON struct',
  );
};

done_testing;
