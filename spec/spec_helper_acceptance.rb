require 'beaker-rspec'

hosts.each do |host|

  install_puppet

  on host, "mkdir -p #{host['distmoduledir']}"
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module
    puppet_module_install(:source => proj_root, :module_name => 'storyboard')
    hosts.each do |host|
      on host, puppet('module','install','puppetlabs-mysql', '--version', '0.6.1'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-apache', '--version', '0.0.4'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-rabbitmq', '--version', '4.0.0'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-puppi', '--version', '2.1.9'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','openstackci-vcsrepo', '--version', '0.0.8'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','stankevich-python', '--version', '1.6.6'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
