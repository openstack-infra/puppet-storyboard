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
# host. If storyboard::cert is defined, it will use a https vhost, otherwise
# it'll just use http.
#
class storyboard::application (

  # Installation parameters
  $install_root           = '/var/lib/storyboard',
  $www_root               = '/var/lib/storyboard/www',
  $server_admin           = undef,
  $hostname               = $::fqdn,

  # storyboard.conf parameters
  $access_token_ttl       = 3600,
  $refresh_token_ttl      = 604800,
  $openid_url,
  $mysql_host             = 'localhost',
  $mysql_port             = 3306,
  $mysql_database         = 'storyboard',
  $mysql_user             = 'storyboard',
  $mysql_user_password    = 'changeme',

  $rabbitmq_host          = 'localhost',
  $rabbitmq_port          = 5672,
  $rabbitmq_vhost         = '/',
  $rabbitmq_user          = 'storyboard',
  $rabbitmq_user_password = 'changemetoo'
) {

  # Variables
  $webclient_url = 'http://tarballs.openstack.org/storyboard-webclient/storyboard-webclient-latest.tar.gz'
  $webclient_filename = 'storyboard-webclient-latest.tar.gz'

  # Dependencies
  require storyboard::params
  include apache
  include apache::mod::wsgi

  class { 'python':
    pip => true,
    dev => true,
  }
  include python::install
  include mysql::python

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
    ensure  => directory,
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
    mode    => '0700',
  }

  # Configure the StoryBoard API
  file { '/etc/storyboard/storyboard.conf':
    ensure  => present,
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
    mode    => '0400',
    content => template('storyboard/storyboard.conf.erb'),
    notify  => Service['httpd'],
    require => [
      Class['apache::params'],
      File['/etc/storyboard']
    ]
  }

  # Download the latest StoryBoard Source
  vcsrepo { '/opt/storyboard':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/storyboard/',
    require  => Package['git']
  }

  # Run pip
  exec { 'install-storyboard' :
    command     => 'pip install /opt/storyboard',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/storyboard'],
    notify      => Service['httpd'],
    require     => [
      Class['apache::params'],
      Class['python::install'],
    ]
  }

  # Create the root dir
  file { $install_root:
    ensure => directory,
    owner  => $storyboard::params::user,
    group  => $storyboard::params::group,
  }

  # Create the log dir
  file { '/var/log/storyboard':
    ensure  => directory,
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
  }

  # Install the wsgi app
  file { "${install_root}/storyboard.wsgi":
    source  => '/opt/storyboard/storyboard/api/app.wsgi',
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
    require => [
      File[$install_root],
      Exec['install-storyboard'],
    ],
    notify  => Service['httpd'],
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
      Class['mysql::python'],
      File['/etc/storyboard/storyboard.conf'],
    ],
    notify      => Service['httpd'],
  }

  file { '/opt/storyboard-webclient':
    ensure      => directory,
    owner       => $storyboard::params::user,
    group       => $storyboard::params::group,
  }

  # Download the latest storyboard-webclient
  exec { 'get-webclient':
    command => "curl ${webclient_url} -z ./${webclient_filename} -o ${webclient_filename}",
    path    => '/bin:/usr/bin',
    cwd     => '/opt/storyboard-webclient',
    require => File['/opt/storyboard-webclient'],
    onlyif  => "curl -I ${webclient_url} -z ./${webclient_filename} | grep '200 OK'",
  }

  # Unpack storyboard-webclient
  exec { 'unpack-webclient':
    command     => "tar -xzf ./${webclient_filename}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    cwd         => '/opt/storyboard-webclient',
    require     => Exec['get-webclient'],
    subscribe   => Exec['get-webclient'],
  }

  # Copy the downloaded source into the configured www_root
  file { $www_root:
    ensure        => directory,
    owner         => $storyboard::params::user,
    group         => $storyboard::params::group,
    require       => Exec['unpack-webclient'],
    source        => '/opt/storyboard-webclient/dist',
    recurse       => true,
    purge         => true,
    force         => true,
    notify        => Service['httpd'],
  }

  # Check vhost permission set.
  $new_vhost_perms = (versioncmp($::apache::apache_version, '2.4') >= 0)

  # Are we setting up TLS or non-TLS?
  if defined(Class['storyboard::cert']) {
    # Set up storyboard as HTTPS
    apache::vhost { $hostname:
      port     => 443,
      docroot  => $www_root,
      priority => '50',
      template => 'storyboard/storyboard_https.vhost.erb',
      ssl      => true,
    }
  } else {
    # Set up storyboard as HTTPS
    apache::vhost { $hostname:
      port     => 80,
      docroot  => $www_root,
      priority => '50',
      template => 'storyboard/storyboard_http.vhost.erb',
      ssl      => false,
    }
  }
}