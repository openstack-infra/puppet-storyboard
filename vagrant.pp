node default {

  if $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease >= 13.10 {
    $hostname = '192.168.99.23'
  } else {
    $hostname = '192.168.99.22'
  }

  class { 'storyboard':
    mysql_user_password    => 'storyboard',
    rabbitmq_user_password => 'storyboard',
    hostname               => $hostname,
  }
}