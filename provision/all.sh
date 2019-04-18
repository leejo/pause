#!/bin/bash

# Execute all the scripts in a directory.
function exec_dir () {
  local dir="$1"
  [[ "${dir:0:1}" == "/" ]] || dir="/vagrant/provision/$dir"
  for exe in "$dir"/*; do
    test -x "$exe" && echo "# $exe" && "$exe"
  done
}

# Execute any before vm initialization scripts.
exec_dir before

# Execute any after vm clean-up scripts.
exec_dir after

# install CPAN dependencies, note we are using the system perl here...
cd /home/vagrant/pause
PERL_MM_USE_DEFAULT=1 cpan App::cpanminus
cpanm --installdeps .

# database setup (note this is DEV setup hence simple passwords)
mysqladmin -u root password "mysql"

mysqladmin -uroot -pmysql create mod
mysql -uroot -pmysql mod < doc/mod.schema.txt
mysql -uroot -pmysql mod -e 'insert into users (userid) values ("LEEJO")'

mysqladmin -uroot -pmysql create authen_pause
mysql -uroot -pmysql authen_pause < doc/authen_pause.schema.txt

LEEJO_PAUSE_PASSWD=$(perl -le 'print crypt "tiger","ef"')
mysql -uroot -pmysql authen_pause -e "insert into usertable (user,password) values ('LEEJO', '$LEEJO_PAUSE_PASSWD')"

# in mysql5.7 root login for localhost changed from password style to
# sudo login style so we have to drop and recreate the root user to
# restore password style login from non-sudo
mysql -u root -pmysql -e " \
DROP USER 'root'@'localhost'; \
CREATE USER 'root'@'%' IDENTIFIED BY 'mysql'; \
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'mysql' WITH GRANT OPTION; \
FLUSH PRIVILEGES;
";

# access to the databases
mkdir -p ../pause-private/lib

cat >> ../pause-private/lib/PrivatePAUSE.pm <<"EndOfFile"
use strict;
package PAUSE;

$ENV{EMAIL_SENDER_TRANSPORT} = 'DevNull';

our $Config;

$Config->{AUTHEN_DATA_SOURCE_USER}  = "root";
$Config->{AUTHEN_DATA_SOURCE_PW}    = "mysql";
$Config->{MOD_DATA_SOURCE_USER}     = "root";
$Config->{MOD_DATA_SOURCE_PW}       = "mysql";
$Config->{MAIL_MAILER}              = ["testfile"];

$Config->{RUNDATA}                  = "/tmp/pause_1999";
$Config->{TESTHOST_SCHEMA}          = "https";

1;
EndOfFile

mkdir -p /tmp/pause_1999;

# config for nginx
mkdir -p /usr/local/nginx/conf

openssl req \
    -new \
    -newkey rsa:4096 \
    -days 365 \
    -nodes \
    -x509 \
    -subj "/C=CH/ST=Vaud/L=Villars/O=PAUSE/CN=pause.perl.org" \
    -keyout /usr/local/nginx/conf/server.key \
    -out /usr/local/nginx/conf/server.crt

cp /home/vagrant/pause/doc/nginx-pause-config.sample /etc/nginx/sites-enabled/nginx-pause-config
nginx -s reload

# Don't let vagrant think the provision failed.
exit 0
