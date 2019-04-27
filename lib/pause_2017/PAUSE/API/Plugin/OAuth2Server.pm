package PAUSE::API::Plugin::OAuth2Server;

use Mojo::Base "Mojolicious::Plugin";
use YAML::Syck;
use Encode;

sub register {
  my ($self, $app, $conf) = @_;

  $app->plugin(
    'OAuth2::Server' => {
      # authorize route falls under /authenquery to make sure user
      # is logged in or is asked to log in
      authorize_route      => '/oauth/authorize',

      # access token route doesn't fall under /authenquery as it will
      # use the oauth2 auth code and client secret for authentication
      access_token_route   => '/oauth/access_token',
      args_as_hash         => 1,

      # FIXME - the following values need to be set in the private
      # config (or eventually - database?)
      access_token_ttl     => 60 * 60 * 24, # 1 day
      jwt_secret           => 'some_strong_secret_key',
      jwt_algorithm        => 'PBES2-HS512+A256KW',

      clients              => {
        ACT => {
         client_secret => "some_strong_client_secret",
        }
      }
    },
  );


}

1;
