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

  # Required parameters
  $openid_url,
  $mysql_user_password,
  $rabbitmq_user_password,

  # Installation parameters
  $src_root_api           = '/opt/storyboard',
  $src_root_webclient     = '/opt/storyboard-webclient',
  $install_root           = '/var/lib/storyboard',
  $www_root               = '/var/lib/storyboard/www',
  $working_root           = '/var/lib/storyboard/spool',
  $server_admin           = undef,
  $hostname               = $::fqdn,
  $cors_allowed_origins   = undef,
  $cors_max_age           = 3600,

  # storyboard.conf parameters
  $authorization_code_ttl = 300,
  $access_token_ttl       = 3600,
  $refresh_token_ttl      = 604800,
  $valid_oauth_clients    = [$::fqdn],
  $enable_token_cleanup   = 'True',

  $mysql_host             = 'localhost',
  $mysql_port             = 3306,
  $mysql_database         = 'storyboard',
  $mysql_user             = 'storyboard',

  $rabbitmq_host          = 'localhost',
  $rabbitmq_port          = 5672,
  $rabbitmq_vhost         = '/',
  $rabbitmq_user          = 'storyboard',
  $enable_notifications   = 'True',

  $enable_cron            = 'True',

  $enable_email           = 'True',
  $sender_email_address   = 'no-reply@storyboard.example.org',
  $default_url            = 'https://storyboard.example.org',
  $smtp_host              = 'localhost',
  $smtp_port              = 25,

) {

  # Variables
  $webclient_filename = 'storyboard-webclient-content-latest.tar.gz'
  $webclient_url = "http://tarballs.openstack.org/storyboard-webclient/${webclient_filename}"

  if $cors_allowed_origins {
    $cors_allowed_origins_string = join($cors_allowed_origins, ',')
  } else {
    $cors_allowed_origins_string = undef
  }

  # Dependencies
  require ::storyboard::params
  include ::httpd
  include ::httpd::mod::wsgi

  class { '::python':
    pip => true,
    dev => true,
  }
  include ::python::install

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
    owner  => $storyboard::params::user,
    group  => $storyboard::params::group,
    mode   => '0700',
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
      Class['httpd::params'],
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
    notify      => Service['httpd'],
    require     => [
      Class['httpd::params'],
      Class['python::install'],
    ]
  }

  # Install launchpad migration dependencies
  if !defined(Package['python-launchpadlib']) {
    package { 'python-launchpadlib':
      ensure => present
    }
  }
  if !defined(Package['python-simplejson']) {
    package { 'python-simplejson':
      ensure => present
    }
  }

  # Create the root dir
  file { $install_root:
    ensure => directory,
    owner  => $storyboard::params::user,
    group  => $storyboard::params::group,
  }

  # Create the working dir
  file { $working_root:
    ensure => directory,
    owner  => $storyboard::params::user,
    group  => $storyboard::params::group,
  }

  # Create the log dir
  file { '/var/log/storyboard':
    ensure => directory,
    owner  => $storyboard::params::user,
    group  => $storyboard::params::group,
  }

  # Install the wsgi app
  file { "${install_root}/storyboard.wsgi":
    source  => "${src_root_api}/storyboard/api/app.wsgi",
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
    require => [
      File[$install_root],
      File[$working_root],
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
      File['/etc/storyboard/storyboard.conf'],
    ],
    notify      => Service['httpd'],
  }

  file { $src_root_webclient:
    ensure => directory,
    owner  => $storyboard::params::user,
    group  => $storyboard::params::group,
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
  file { $www_root:
    ensure  => directory,
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
    require => File["${src_root_webclient}/dist/config.json"],
    source  => "${src_root_webclient}/dist",
    recurse => true,
    purge   => true,
    force   => true,
    notify  => Service['httpd'],
  }

  # Check vhost permission set.
  $new_vhost_perms = (versioncmp($::storyboard::params::apache_version, '2.4') >= 0)

  # Are we setting up TLS or non-TLS?
  if defined(Class['storyboard::cert']) {
    # Set up storyboard as HTTPS
    ::httpd::vhost { $hostname:
      port     => 443,
      docroot  => $www_root,
      priority => '50',
      template => 'storyboard/storyboard_https.vhost.erb',
      ssl      => true,
    }
  } else {
    # Set up storyboard as HTTPS
    ::httpd::vhost { $hostname:
      port     => 80,
      docroot  => $www_root,
      priority => '50',
      template => 'storyboard/storyboard_http.vhost.erb',
      ssl      => false,
    }
  }
}
