package PAUSE::API::Controller::User;

use Mojo::Base "Mojolicious::Controller";
use HTTP::Status qw/:constants status_message/;

sub me {
  my ( $c ) = @_;

  my $oauth_details = $c->oauth;
  my $user_id = $oauth_details->{user_id};

  my $mgr = $c->app->pause;
  my $dbh = $mgr->connect;
  my $query = qq{
    SELECT userid, email, homepage
    FROM   users
    WHERE  userid = ?
  };

  my $sth = $dbh->prepare($query);
  $sth->execute( $user_id );

  my ( $u_id,$email,$web ) = $sth->fetchrow_array;

  return $c->render( json => {
    pause_id => $u_id,
    email => $email,
    homepage => $web || undef,
  } );
}

sub oauth_authorize {
  my ( $c ) = @_;

  my $u = $c->active_user_record;

  my $redirect_uri = $c->oauth2_auth_request({
    user_id => $u->{userid},
  });

  if ( $redirect_uri ) {
    return $c->redirect_to( $redirect_uri );
  }

  # something didn't work, e.g. bad client, scopes, etc
  my $error = "Failed to generate a redirect_uri for oauth_authorize";
  $c->app->pause->log({level => 'error', message => $error });
  $c->res->code(HTTP_INTERNAL_SERVER_ERROR);
  return $c->render(
    status => HTTP_BAD_REQUEST,
    json => { error => "Bad request" },
  )
}

1;
