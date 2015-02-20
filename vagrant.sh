#!/bin/sh

# Install Puppet!
if [ ! -f /etc/apt/sources.list.d/puppetlabs.list ]; then
  lsbdistcodename=`lsb_release -c -s`
  puppet_deb=puppetlabs-release-${lsbdistcodename}.deb
  wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
  sudo dpkg -i puppetlabs-release-precise.deb
  sudo apt-get update
  sudo apt-get dist-upgrade -y
fi

if [ ! -d /etc/puppet/modules/stdlib ]; then
  puppet module install puppetlabs-stdlib --version 3.2.0
fi
if [ ! -d /etc/puppet/modules/mysql ]; then
  puppet module install puppetlabs-mysql --version 0.6.1
fi
if [ ! -d /etc/puppet/modules/apache ]; then
  puppet module install puppetlabs-apache --version 0.0.4
fi
if [ ! -d /etc/puppet/modules/rabbitmq ]; then
  puppet module install puppetlabs-rabbitmq --version 5.0.0
fi
if [ ! -d /etc/puppet/modules/puppi ]; then
  puppet module install example42-puppi --version 2.1.9
fi
if [ ! -d /etc/puppet/modules/vcsrepo ]; then
  puppet module install openstackci-vcsrepo --version 0.0.8
fi
if [ ! -d /etc/puppet/modules/python ]; then
  puppet module install stankevich-python --version 1.6.6
fi
if [ ! -d /etc/puppet/modules/storyboard ]; then
  sudo ln -s /vagrant /etc/puppet/modules/storyboard
fi