# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: storyboard::application
#
# This module installs the storyboard webclient and the api onto the current
# host. It does not install any apache2 wsgi host - for that please choose
# to include either storyboard::apache::http or storyboard::apache::https.
#
class storyboard::application () {

  # Load parameters
  require storyboard::params

  # Download source for the webclient tarball
  $webclient_filename     = $storyboard::params::webclient_filename
  $webclient_url          = $storyboard::params::webclient_url

  # The user under which storyboard will run.
  $user                   = $storyboard::params::user
  $group                  = $storyboard::params::group

  # Installation parameters
  $src_root_api           = $storyboard::params::src_root_api
  $src_root_webclient     = $storyboard::params::src_root_webclient
  $install_root_api       = $storyboard::params::install_root_api
  $install_root_webclient = $storyboard::params::install_root_webclient
  $working_root           = $storyboard::params::working_root

  class { 'python':
    pip => true,
    dev => true,
  }
  include python::install

  if !defined(Package['git']) {
    package { 'git':
      ensure => present
    }
  }

  if !defined(Package['curl']) {
    package { 'curl':
      ensure => present
    }
  }

  # Create the storyboard configuration directory.
  file { '/etc/storyboard':
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0700',
  }

  # Configure the StoryBoard API
  file { '/etc/storyboard/storyboard.conf':
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0400',
    content => template('storyboard/storyboard.conf.erb'),
    require => [
      File['/etc/storyboard']
    ]
  }

  # Download the latest StoryBoard Source
  vcsrepo { $src_root_api:
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/storyboard/',
    require  => Package['git']
  }

  # Run pip
  exec { 'install-storyboard' :
    command     => "pip install ${src_root_api}",
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo[$src_root_api],
    require     => [
      Class['python::install'],
    ]
  }

  # Create the root dir
  file { $install_root_api:
    ensure  => directory,
    owner   => $user,
    group   => $group,
  }

  # Create the working dir
  file { $working_root:
    ensure  => directory,
    owner   => $user,
    group   => $group,
  }

  # Create the log dir
  file { '/var/log/storyboard':
    ensure  => directory,
    owner   => $user,
    group   => $group,
  }

  # Migrate the database
  exec { 'migrate-storyboard-db':
    command     => 'storyboard-db-manage --config-file /etc/storyboard/storyboard.conf upgrade head',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => [
      Exec['install-storyboard'],
      File['/etc/storyboard/storyboard.conf'],
    ],
    require     => [
      File['/etc/storyboard/storyboard.conf'],
    ],
  }

  file { $src_root_webclient:
    ensure  => directory,
    owner   => $user,
    group   => $group,
  }

  # Download the latest storyboard-webclient
  exec { 'get-webclient':
    command => "curl ${webclient_url} -z ./${webclient_filename} -o ${webclient_filename}",
    path    => '/bin:/usr/bin',
    cwd     => $src_root_webclient,
    require => File[$src_root_webclient],
    onlyif  => "curl -I ${webclient_url} -z ./${webclient_filename} | grep '200 OK'",
  }

  # Unpack storyboard-webclient
  exec { 'unpack-webclient':
    command     => "tar -xzf ./${webclient_filename}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    cwd         => $src_root_webclient,
    require     => Exec['get-webclient'],
    subscribe   => Exec['get-webclient'],
  }

  # Create config.json
  file { "${src_root_webclient}/dist/config.json":
    ensure  => file,
    content => '{}',
    require => Exec['unpack-webclient'],
  }

  # Copy the downloaded source into the configured www_root
  file { $install_root_webclient:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    require => File["${src_root_webclient}/dist/config.json"],
    source  => "${src_root_webclient}/dist",
    recurse => true,
    purge   => true,
    force   => true,
  }
}
