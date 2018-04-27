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
class storyboard::params () {

  include ::httpd::params

  $user = $::httpd::params::user
  $group = $::httpd::params::group

  case $::osfamily {
    'Debian': {
      if $::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemrelease, '13.10') >= 0 {
        $apache_version = '2.4'
        $manage_rabbit_repo = false
      } else {
        $apache_version = '2.2'
        $manage_rabbit_repo = true
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'storyboard' module only supports osfamily Debian.")
    }
  }
}
