package PAUSE::TestPAUSE::Result;
use Moose;
use MooseX::StrictConstructor;

use DBI;
use Path::Class;

use namespace::autoclean;

has tmpdir => (
  reader => '_tmpdir_obj',
  isa    => 'Object',
  required => 1,
);

sub tmpdir {
  my ($self) = @_;
  return dir($self->_tmpdir_obj);
}

has config_overrides => (
  reader   => '_config_overrides',
  isa      => 'HashRef[Str]',
  required => 1,
);

has [ qw(authen_db_file mod_db_file) ] => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

sub __connect {
  my ($self, $file) = @_;

  return DBI->connect(
    'dbi:SQLite:dbname=' . $file,
    undef,
    undef,
  ) or die "can't connect to db at $file: $DBI::errstr";
}

sub connect_authen_db {
  my ($self) = @_;
  return $self->__connect( $self->authen_db_file );
}

sub connect_mod_db {
  my ($self) = @_;
  return $self->__connect( $self->mod_db_file );
}

1;
