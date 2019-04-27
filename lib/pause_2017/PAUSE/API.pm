package PAUSE::API;

use Mojo::Base "Mojolicious";
use MojoX::Log::Dispatch::Simple;
use HTTP::Status qw/:constants status_message/;

has pause => sub { Carp::confess "requires PAUSE::Web::Context" };

sub startup {
  my $app = shift;

  $app->moniker("pause-web");

  $app->max_request_size(0); # indefinite upload size

  # Set the same logger as the one Plack uses
  # (initialized in app.psgi)
  $app->log(MojoX::Log::Dispatch::Simple->new(
    dispatch => $app->pause->logger,
    level => "debug",
  ));

  $app->hook(around_dispatch => \&_log);

  # Load plugins to modify path/set stash values/provide helper methods
  $app->plugin("PAUSE::Web::Plugin::ConfigPerRequest");
  $app->plugin("PAUSE::Web::Plugin::GetActiveUserRecord");

  # Check HTTP headers and set stash
  my $r = $app->routes->under("/")->to("root#check");

  # API routing

  # note that we define the /oauth/authorize route before we install
  # the plugin to avoid it defining it first (FIFO) - we use the same
  # route in the plugin setup to avoid it defining an alternate route
  $app->routes->get("/oauth/authorize")->to("user#oauth_authorize");
  $app->plugin("PAUSE::API::Plugin::OAuth2Server");

  # API/OAuth2
  my $api = $app->routes->under("/")->to(
    cb => sub {
      my ( $c ) = @_;
      return 1 if $c->oauth;
      $c->render(
        status => HTTP_UNAUTHORIZED,
        json   => { error => 'Bad credentials' },
      );
      return;
    }
  );

  $api->get("/me")->to("user#me");
}

sub _log {
  my ($next, $c) = @_;
  local $SIG{__WARN__} = sub {
    my $message = shift;
    chomp $message;
    Log::Dispatch::Config->instance->log(
      level => 'warn',
      message => $message,
    );
  };
  $c->helpers->reply->exception($@) unless eval { $next->(); 1 };
}

1;
