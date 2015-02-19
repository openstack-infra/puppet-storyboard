node default {
  class { 'storyboard':
    mysql_user_password    => 'storyboard',
    rabbitmq_user_password => 'storyboard',
  }
}