name							"keystone"
maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Installs and configures the Keystone Identity Service"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.20"
recipe            "keystone::server", "Installs packages required for a keystone server"
recipe            "keystone::keystone-api", "Installs packages required for an additional keystone server in HA environment"

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ database monitoring mysql openssl osops-utils }.each do |dep|
  depends dep
end
