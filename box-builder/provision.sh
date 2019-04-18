#!/bin/bash

set -o errexit
set -e -o pipefail

echo "vagrant provision: $0"

# https://serverfault.com/a/500778/119512
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure --frontend=noninteractive locales

apt-get update

# some nice to haves for working on the box
apt-get -q --assume-yes install vim
apt-get -q --assume-yes install sudo
apt-get -q --assume-yes install openssh-server
apt-get -q --assume-yes install git
apt-get -q --assume-yes install aptitude
apt-get -q --assume-yes install curl

# some must haves for running the app/installing CPAN deps
apt-get -q --assume-yes install default-libmysqlclient-dev
apt-get -q --assume-yes install libxml2-dev
apt-get -q --assume-yes install libexpat-dev
apt-get -q --assume-yes install libssl-dev

# some must have for other required services
apt-get -q --assume-yes install mysql-server
apt-get -q --assume-yes install nginx
