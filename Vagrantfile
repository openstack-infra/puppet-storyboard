# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Create an ubuntu/precise box against which we can run our module.
  config.vm.define "precise" do |precise|
    # Define the box.
    precise.vm.box = "ubuntu/precise64"
    precise.vm.hostname = "puppet-storyboard-precise64"

    config.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id,'--memory', '2048']
      vb.name = 'puppet-storyboard-precise64'
    end

    # Grant a private IP
    precise.vm.network "private_network", ip: "192.168.99.22"
  end

  # Create an ubuntu/trusty box against which we can run our module.
  config.vm.define "trusty" do |trusty|
    # Define the box.
    trusty.vm.box = "ubuntu/trusty64"
    trusty.vm.hostname = "puppet-storyboard-trusty64"

    config.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id,'--memory', '2048']
      vb.name = 'puppet-storyboard-trusty64'
    end

    # Grant a private IP
    trusty.vm.network "private_network", ip: "192.168.99.23"
  end

  # All VM's run the same provisioning
  config.vm.provision "shell", path: "vagrant.sh"
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = ['vm', "/vagrant"]
    puppet.manifest_file = "vagrant.pp"
  end
end
