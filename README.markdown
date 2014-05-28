# OpenStack StoryBoard Module

Michael Krotscheck <krotscheck@gmail.com>

This module manages and installs OpenStack StoryBoard. It can be installed either as a standalone instance with all dependencies included, or buffet-style per component.

# Quick Start

To install StoryBoard and configure it with sane defaults, include the following in your site.pp file:

    node default {
    	include storyboard
	}

# Configuration

The StoryBoard puppet module is separated into individual components which StoryBoard needs to run. These can be installed independently, however configuration is shared between all components via storyboard::params. Available configuration parameters, and their defaults, are listed below.

	node default {
		class { 'storyboard::params':
			
		}
	}

## StoryBoard API
The storyboard::api module 

The Puppet Dashboard Face requires that the cloud provisioner version 1.0.0 is installed
and in Ruby's loadpath (which can be set with the RUBYLIB environment variable)

To use the Puppet Dashboard Face:


* Ensure that you have Puppet 2.7.6 or greater installed.  This face MAY work on version 2.7.2 or later, but it's not been tested.
* Download or clone puppetlabs-dashboard to your Puppet modulepath (i.e. ~/.puppet/modules or /etc/puppet/modules)
        export RUBYLIB=/etc/puppet/modules/dashboard/lib:$RUBYLIB

* Test the face and learn more about its usage

        puppet help dashboard

# Feature Requests

* Sqlite support.
* Integration with Puppet module to set puppet.conf settings.
* Remove the need to set the MySQL root password (needs fixed in the mysql module)
