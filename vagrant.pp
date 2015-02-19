node default {
  class { 'storyboard':
    mysql_user_password    => 'storyboard',
    rabbitmq_user_password => 'storyboard',
    hostname               => '192.168.99.22',
  }
}