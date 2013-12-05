name		  "keystone"
maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Installs and configures the Keystone Identity Service"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           IO.read(File.join(File.dirname(__FILE__), 'VERSION'))
recipe            "keystone::setup", "Installs packages required for a keystone server"
recipe            "keystone::keystone-api", "Installs packages required for an additional keystone server in HA environment"
recipe            "keystone::keystone-ssl", "Sets up Keystone to use Apache mod_wsgi"

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ database mysql openssl osops-utils apache2 }.each do |dep|
  depends dep
end
