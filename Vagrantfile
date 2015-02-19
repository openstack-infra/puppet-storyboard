# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "puppet-storyboard"

  # Private network so we have a static IP to map against instead of
  # crazy insecure port forwarding.
  config.vm.network "private_network", ip: "192.168.99.22"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id,'--memory', '2048']
    vb.name = 'puppet-storyboard'
    end

  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = ['vm', "/vagrant"]
    puppet.manifest_file = "vagrant.pp"
  end
end
