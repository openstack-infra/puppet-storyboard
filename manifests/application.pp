#
# This module installs the storyboard webclient and the api onto the current
# host.
#
class storyboard::application (
  $www_root,
  $hostname,
  $token_ttl,
  $openid_url,
  $mysql_host,
  $mysql_port,
  $mysql_database,
  $mysql_user,
  $mysql_user_password,
  $ssl_cert_path = undef,
  $ssl_key_path  = undef,
  $ssl_ca_path   = undef
) {

  # Dependencies
  include apache
  include apache::params
  include apache::service
  include apache::mod::wsgi

  require mysql::bindings
  require mysql::bindings::python

  if !defined(Package['python']) {
    package { 'python':
      ensure => installed
    }
  }
  if !defined(Package['python-dev']) {
    package { 'python-dev':
      ensure => installed
    }
  }
  if !defined(Package['python-pip']) {
    package { 'python-pip':
      ensure => installed
    }
  }
  if !defined(Package['git']) {
    package { 'git':
      ensure => installed
    }
  }

  # Configure the StoryBoard API
  file { '/etc/storyboard.conf':
    ensure  => present,
    owner   => $apache::params::user,
    group   => $apache::params::group,
    mode    => '0400',
    content => template('storyboard/storyboard.conf.erb'),
    notify  => Class['apache::service']
  }

  # Download the latest StoryBoard Source
  vcsrepo { '/usr/src/storyboard':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/storyboard/',
  }

  # Run pip
  exec { 'install-storyboard' :
    command     => 'pip install /usr/src/storyboard',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/usr/src/storyboard'],
    require     => Package['python-pip'],
    notify      => Class['apache::service']
  }

  # Create the root dir
  file { '/var/lib/storyboard':
    ensure    => directory,
    owner     => $apache::params::user,
    group     => $apache::params::group
  }

  # Install the wsgi app
  file { '/var/lib/storyboard/storyboard.wsgi':
    source      => '/usr/src/storyboard/storyboard/api/app.wsgi',
    owner       => $apache::params::user,
    group       => $apache::params::group,
    require     => [
      File['/var/lib/storyboard'],
      Exec['install-storyboard']
    ],
    notify      => Class['apache::service']
  }

  # Migrate the database
  exec { 'migrate-storyboard-db':
    command     => 'storyboard-db-manage --config-file /etc/storyboard.conf upgrade head',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Exec['install-storyboard'],
    require     => Class['mysql::bindings::python'],
    notify      => Class['apache::service']
  }

  # Download the latest storyboard-webclient
  puppi::netinstall { 'storyboard-webclient':
    url             => 'http://tarballs.openstack.org/storyboard-webclient/storyboard-webclient-latest.tar.gz',
    destination_dir => '/usr/src/storyboard-webclient',
    extracted_dir   => 'dist'
  }

  # Copy the downloaded source into the configured www_root
  file { "${www_root}":
    ensure      => directory,
    owner       => $apache::params::user,
    group       => $apache::params::group,
    require     => Puppi::Netinstall['storyboard-webclient'],
    source      => '/usr/src/storyboard-webclient/dist',
    recurse     => true,
    purge       => true,
    force       => true,
    notify      => Class['apache::service']
  }

  # Are we setting up TLS or non-TLS?
  if defined($ssl_cert_path) and defined($ssl_key_path) {

    # Set up storyboard as HTTPS
    apache::vhost { "storyboard":
      servername                  => $hostname,
      port                        => '443',
      ssl                         => true,
      vhost_name                  => '*',
      docroot                     => $www_root,
      ssl_cert                    => $ssl_cert_path,
      ssl_key                     => $ssl_key_path,
      ssl_ca                      => $ssl_ca_path,
      wsgi_daemon_process         => 'storyboard',
      wsgi_daemon_process_options => {
        user    => $apache::params::user,
        group   => $apache::params::group,
        threads => '5'
      },
      wsgi_script_aliases         => {
        '/api' => '/var/lib/storyboard/storyboard.wsgi'
      },
      custom_fragment             => 'WSGIPassAuthorization On'
    }

  } else {

    # Set up storyboard as HTTP
    apache::vhost { "storyboard":
      servername                  => $hostname,
      port                        => '80',
      vhost_name                  => '*',
      docroot                     => $www_root,
      wsgi_daemon_process         => 'storyboard',
      wsgi_daemon_process_options => {
        user    => $apache::params::user,
        group   => $apache::params::group,
        threads => '5'
      },
      wsgi_script_aliases         => {
        '/api' => '/var/lib/storyboard/storyboard.wsgi'
      },
      custom_fragment             => 'WSGIPassAuthorization On'
    }
  }
}