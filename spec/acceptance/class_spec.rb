require 'spec_helper_acceptance'

describe 'storyboard class' do

  context 'default parameters' do
    hosts.each do |host|
      if fact('osfamily') == 'RedHat'
        if fact('architecture') == 'amd64'
          on host, "wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm; rpm -ivh epel-release-6-8.noarch.rpm"
        else
          on host, "wget http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm; rpm -ivh epel-release-6-8.noarch.rpm"
        end
      end
    end

    it 'should work with no errors' do
      pp= <<-EOS
        class { 'storyboard':
            mysql_database         => 'storyboard',
            mysql_user             => 'storyboard',
            mysql_user_password    => 'changeme',

            rabbitmq_user          => 'storyboard',
            rabbitmq_user_password => 'changemetoo',

            hostname               => ::fqdn,
            openid_url             => 'https://login.launchpad.net/+openid',
            ssl_cert_file          => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
            ssl_cert_content       => undef,
            ssl_key_file           => '/etc/ssl/private/ssl-cert-snakeoil.key',
            ssl_key_content        => undef,
            ssl_ca_file            => undef,
            ssl_ca_content         => undef
        }

      EOS


      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

  end
end
