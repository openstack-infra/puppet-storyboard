# Class: puppet::storyboard
#
# This class installs and configures OpenStack StoryBoard.
#
# Parameters:
#   [*www_root*]
#     - WWW-Root from which the webclient will be served.
#
#   [*hostname*]
#     - The virtual hostname on which StoryBoard will be served.
#
#   [*token_ttl*]
#     - The expiration time, in seconds, for StoryBoard's access tokens.
#
#   [*openid_url*]
#     - The OpenID URL endpoint to use for authentication.
#
#   [*ssl_cert_path*]
#     - (Optional) Absolute path to the Certificate file for the StoryBoard
#       Virtual Host
#
#   [*ssl_key_path*]
#     - (Optional) Absolute path to the Private Key file for the StoryBoard
#       Virtual Host
#
#   [*ssl_ca_path*]
#     - (Optional) Absolute path to the CA Chain certificate to use for the
#       StoryBoard Virtual Host.
#
#   [*mysql_host*]
#     - Hostname of the mysql server which StoryBoard
#       will use.
#
#   [*mysql_port*]
#     - The port on which the mysql server is listening
#       for connections.
#
#   [*mysql_database*]
#     - The name of the mysql database to use.
#
#   [*mysql_user*]
#     - The user name which StoryBoard will use to log in
#       to the mysql host.
#
#   [*mysql_user_password*]
#     - Password for the mysql user.
#
#   [*mysql_root_password*]
#     - The root password to set if you're installing
#       StoryBoard as a standalone instance.
#
# Sample Usage:
#   class {'storyboard':
#     www_root             => '/var/lib/storyboard/www',
#     hostname             => ::fqdn,
#     token_ttl            => 86400,
#     openid_url           => 'https://login.launchpad.net/+openid',
#     ssl_cert_path        => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
#     ssl_key_path         => '/etc/ssl/private/ssl-cert-snakeoil.key',
#     ssl_ca_path          => undef,
#     mysql_host           => 'localhost',
#     mysql_port           => 3306,
#     mysql_database       => 'storyboard',
#     mysql_user           => 'storyboard',
#     mysql_user_password  => 'changeme',
#     mysql_root_password  => 'changemetoo'
#   }
#
class storyboard (
  $www_root             = '/var/lib/storyboard/www',
  $hostname             = $::fqdn,
  $token_ttl            = 86400,
  $openid_url           = 'https://login.launchpad.net/+openid',
  $ssl_cert_path        = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_key_path         = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ssl_ca_path          = undef,
  $mysql_host           = 'localhost',
  $mysql_port           = 3306,
  $mysql_database       = 'storyboard',
  $mysql_user           = 'storyboard',
  $mysql_user_password  = 'changeme',
  $mysql_root_password  = 'changemetoo'
) {

  # Install mysql
  class { 'storyboard::mysql':
    mysql_database      => $mysql_database,
    mysql_user          => $mysql_user,
    mysql_user_password => $mysql_user_password,
    mysql_root_password => $mysql_root_password
  }

  # Install the application
  class { 'storyboard::application':
    www_root            => $www_root,
    hostname            => $hostname,
    token_ttl           => $token_ttl,
    openid_url          => $openid_url,
    ssl_cert_path       => $ssl_cert_path,
    ssl_key_path        => $ssl_key_path,
    ssl_ca_path         => $ssl_ca_path,
    mysql_host          => 'localhost',
    mysql_port          => 3306,
    mysql_database      => $mysql_database,
    mysql_user          => $mysql_user,
    mysql_user_password => $mysql_user_password,
  }
}

