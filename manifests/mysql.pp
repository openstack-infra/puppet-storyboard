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

# == Class: storyboard::mysql
#
# The StoryBoard MySQL manifest will install a standalone, localhost instance
# of mysql for storyboard to connect to.
#
class storyboard::mysql () {

  require storyboard::params

  # Import parameters.
  $mysql_database      = $storyboard::params::mysql_database
  $mysql_user          = $storyboard::params::mysql_user
  $mysql_user_password = $storyboard::params::mysql_user_password

  # Install MySQL
  include mysql::server

  # Add the storyboard database.
  mysql::db { $mysql_database:
    user     => $mysql_user,
    password => $mysql_user_password,
    host     => 'localhost',
    grant    => ['all'],
  }
}