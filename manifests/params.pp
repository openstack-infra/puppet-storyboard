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

# == Class: storyboard::params
#
# Centralized configuration management for the storyboard module.
#
class storyboard::params (

  # The user under which storyboard will run.
  $user                   = $apache::params::user,
  $group                  = $apache::params::group,
  $server_admin           = undef,
  $hostname               = $::ipaddress,

  # [default] storyboard.conf
  $enable_notifications   = true,

  # [oauth] storyboard.conf
  $openid_url             = 'https://login.launchpad.net/+openid',
  $authorization_code_ttl = 300,
  $access_token_ttl       = 3600,
  $refresh_token_ttl      = 604800,
  $valid_oauth_clients    = ['storyboard.openstack.org'],

  # [cron] storyboard.conf
  $enable_cron            = true,

  # [cors] storyboard.conf
  $cors_allowed_origins   = [],
  $cors_max_age           = 3600,

  # [database] storyboard.conf
  $mysql_user             = 'storyboard',
  $mysql_user_password,
  $mysql_host             = localhost,
  $mysql_port             = 3306,
  $mysql_database         = 'storyboard',

  # [notifications] storyboard.conf
  $rabbitmq_host          = 'localhost',
  $rabbitmq_port          = 5672,
  $rabbitmq_vhost         = '/',
  $rabbitmq_user          = 'storyboard',
  $rabbitmq_user_password,

  # [plugin_token_cleaner] storyboard.conf
  $enable_token_cleanup   = 'True',

  # StoryBoard Worker configuration
  $worker_count           = 5,
  $worker_use_upstart     = false,

  # Apache2 ssl configuration
  $ssl_cert_content = undef,
  $ssl_cert         = '/etc/ssl/certs/storyboard.pem',
  $ssl_key_content  = undef,
  $ssl_key          = '/etc/ssl/private/storyboard.key',
  $ssl_ca_content   = undef,
  $ssl_ca           = undef, # '/etc/ssl/certs/ca.pem'
) inherits apache::params {

  # Define the python version
  $python_version = '2.7'

  # Working and Install directories
  $src_root_api           = "/opt/storyboard-py${python_version}"
  $src_root_webclient     = "/opt/storyboard-webclient"
  $install_root_api       = "/var/lib/storyboard-py${python_version}"
  $install_root_webclient = "${$install_root_api}/www"
  $working_root           = "${$install_root_api}/spool"

  # Download source
  $webclient_filename     = 'storyboard-webclient-latest.tar.gz'
  $webclient_url          = "http://tarballs.openstack.org/storyboard-webclient/${webclient_filename}"

  # Build the connection string from individual parameters
  $mysql_connection_string = "mysql+pymysql://${mysql_user}:${mysql_user_password}@${mysql_host}:${mysql_port}/${mysql_database}"

  # CA file needs special treatment, since we want the path variable
  # to be undef in some cases.
  if $ssl_ca == undef and $ssl_ca_content != undef {
    $resolved_ssl_ca = '/etc/ssl/certs/storyboard.ca.pem'
  } else {
    $resolved_ssl_ca = $ssl_ca
  }

  if $::operatingsystemrelease < 14.04 {
    fail("Unsupported operating system: The 'storyboard' module only supports ubuntu trusty.")
  }
}
