# PAUSE

### The [Perl programming] Authors Upload Server

[http://pause.perl.org/](http://pause.perl.org/)

To build a development box you will need VirtualBox and Vagrant.

git clone this repo then build the box that also install all necessary dependencies:

    VAGRANT_VAGRANTFILE=box-builder/Vagrantfile vagrant up
    VAGRANT_VAGRANTFILE=box-builder/Vagrantfile vagrant halt
    vagrant up --provision

This make take around 30 minutes or so. Once the above is done you can:

    vagrant ssh
    cd pause
    perl Makefile.PL
    make test

And if tests pass:

    plackup -I ../pause-private/lib

Or for the mojolicious based server:

    plackup -I ../pause-private/lib --path / app_2017.psgi

You should then be able to access PAUSE on `https://192.168.56.1`

For more information about setup, development, and deployment see `doc/README`
