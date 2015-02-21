# Copyright (c) 2015 Hewlett-Packard Development Company, L.P.
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

# == Class: storyboard::apache::http
#
# This module installs the storyboard webclient and the api onto the current
# host using an unecrypted http protocol.
#
class storyboard::apache::http () {
  require storyboard::params

  # Pull various variables into this module, for slightly saner templates.
  $src_root_api           = $storyboard::params::src_root_api
  $src_root_webclient     = $storyboard::params::src_root_webclient
  $install_root_api       = $storyboard::params::install_root_api
  $install_root_webclient = $storyboard::params::install_root_webclient
  $hostname               = $storyboard::params::hostname
  $user                   = $storyboard::params::user
  $group                  = $storyboard::params::group
  $server_admin           = $storyboard::params::server_admin
  $new_vhost_perms        = $storyboard::params::new_vhost_perms
  $python_version         = $storyboard::params::python_version

  # Install apache
  include apache
  include apache::mod::wsgi

  # Set up storyboard as HTTP
  apache::vhost { $hostname:
    port     => 80,
    docroot  => $install_root_webclient,
    priority => '50',
    template => 'storyboard/storyboard_http.vhost.erb',
    ssl      => false,
    notify   => Service['httpd'],
  }
}
