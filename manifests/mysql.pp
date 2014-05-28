#
# The StoryBoard MySQL manifest will install a standalone, localhost instance
# of mysql for storyboard to connect to.
#
class storyboard::mysql (
  $mysql_database,
  $mysql_user,
  $mysql_user_password,
  $mysql_root_password
) {

  # Install MySQL with the given root password.
  class { 'mysql::server':
    root_password    => $mysql_root_password
  }

  # Add the storyboard database.
  mysql_database { "${mysql_database}":
    ensure  => 'present',
    charset => 'utf8',
    collate => 'utf8_general_ci',
    require => Class['mysql::server']
  }

  # Add the storyboard user.
  mysql_user { "${mysql_user}@localhost":
    ensure  => 'present',
    password_hash => mysql_password("${mysql_user_password}"),
    require    => Mysql_database["${mysql_database}"]
  }

  # Grant privileges to the storyboard user.
  mysql_grant { "${mysql_user}@localhost/${mysql_database}.*":
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => "${mysql_database}.*",
    user       => "${mysql_user}@localhost",
    require    => Mysql_user["${mysql_user}@localhost"]
  }
}