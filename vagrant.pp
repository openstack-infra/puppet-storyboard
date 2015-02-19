node 'puppet-storyboard-precise64' {
  class { 'storyboard':
    mysql_user_password    => 'storyboard',
    rabbitmq_user_password => 'storyboard',
    hostname               => '192.168.99.22',
  }
}

node 'puppet-storyboard-trusty64' {
  class { 'storyboard':
    mysql_user_password    => 'storyboard',
    rabbitmq_user_password => 'storyboard',
    hostname               => '192.168.99.23',
  }
}