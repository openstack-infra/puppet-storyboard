# Copyright (c) 2014 Mirantis Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: storyboard
#
# This class will install a fully functional standalone instance of
# storyboard on the current instance. It includes database setup and
# a set of sane configuration defaults. For more precise configuration,
# please use individual submodules.
#
class storyboard (
  $mysql_database      = 'storyboard',
  $mysql_user          = 'storyboard',
  $mysql_user_password,
  $rabbitmq_user       = 'storyboard',
  $rabbitmq_user_password,
  $hostname            = $::ipaddress,
  $openid_url          = 'https://login.launchpad.net/+openid',
) {

  # Configure the entire storyboard instance. This does not install anything,
  # but ensures that variables are consistent across all modules.
  class { '::storyboard::params':
    mysql_database         => $mysql_database,
    mysql_user             => $mysql_user,
    mysql_user_password    => $mysql_user_password,

    ssl_cert               => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key                => '/etc/ssl/private/ssl-cert-snakeoil.key',

    rabbitmq_user          => $rabbitmq_user,
    rabbitmq_user_password => $rabbitmq_user_password,

    valid_oauth_clients    => [$hostname],

    hostname               => $hostname,
    openid_url             => $openid_url,
  }

  include ::storyboard::apache::http
  include ::storyboard::rabbit
  include ::storyboard::mysql
  include ::storyboard::application
  include ::storyboard::workers
}
