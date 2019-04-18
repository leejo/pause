ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

Vagrant.configure("2") do |config|

    config.vm.box = "debian/stretch64"

    # Use PAUSE_DEVELOPER_* env vars to set vm hardware resources.
    vbox_custom = %w[cpus memory].map do |hw|
        key = "PAUSE_DEVELOPER_#{hw.upcase}"
        ENV[key] ? ["--#{hw}", ENV[key]] : []
    end.flatten

    config.vm.post_up_message = $msg

    config.vm.provider :virtualbox do |vb|
        vb.name = "pause-stretch"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        if not vbox_custom.empty?
            vb.customize [ "modifyvm", :id, *vbox_custom ]
        end
    end

    config.vm.network "forwarded_port", guest: 80, host: 80 # apache http
    config.vm.network "forwarded_port", guest: 443, host: 443 # apache https
    config.vm.network "forwarded_port", guest: 5000, host: 5000 # PAUSE (non-TLS)

    config.vm.synced_folder '.', '/vagrant', disabled: true
    config.vm.synced_folder ".", "/home/vagrant/pause"

    config.vm.provision :shell, :path => 'provision/all.sh'
end
