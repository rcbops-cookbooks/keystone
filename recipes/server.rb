#
# Cookbook Name:: keystone
# Recipe:: server
#
# Copyright 2012, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "keystone::keystone-rsyslog"
include_recipe "mysql::client"
include_recipe "mysql::ruby"
include_recipe "osops-utils"
include_recipe "monitoring"

# Allow for using a well known db password
if node["developer_mode"]
  node.set_unless["keystone"]["db"]["password"] = "keystone"
  node.set_unless["keystone"]["admin_token"] = "999888777666"
  node.set_unless["keystone"]["users"]["monitoring"]["password"] = "monitoring"
else
  node.set_unless["keystone"]["db"]["password"] = secure_password
  node.set_unless["keystone"]["admin_token"] = secure_password
  node.set_unless["keystone"]["users"]["monitoring"]["password"] = secure_password
end

platform_options = node["keystone"]["platform"]

#creates db and user, returns connection info, defined in osops-utils/libraries
mysql_info = create_db_and_user("mysql",
                                node["keystone"]["db"]["name"],
                                node["keystone"]["db"]["username"],
                                node["keystone"]["db"]["password"])
mysql_connect_ip = get_access_endpoint('mysql-master', 'mysql', 'db')["host"]

##### NOTE #####
# https://bugs.launchpad.net/ubuntu/+source/keystone/+bug/931236 (Resolved)
# https://bugs.launchpad.net/ubuntu/+source/keystone/+bug/1073273
################

platform_options["mysql_python_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

platform_options["keystone_packages"].each do |pkg|
  package pkg do
    if node["osops"]["do_package_upgrades"]
      action :upgrade
    else
      action :install
    end
    options platform_options["package_options"]
  end
end

platform_options["keystone_ldap_packages"].each do |pkg|
  package pkg do
    if node["osops"]["do_package_upgrades"]
      action :upgrade
    else
      action :install
    end
    options platform_options["package_options"]
  end
end

execute "Keystone: sleep" do
  command "sleep 10s"
  action :nothing
end

service "keystone" do
  service_name platform_options["keystone_service"]
  supports :status => true, :restart => true
  action [ :enable ]
  notifies :run, resources(:execute => "Keystone: sleep"), :immediately
end

monitoring_procmon "keystone" do
  procname=platform_options["keystone_service"]
  sname=platform_options["keystone_process_name"]
  process_name sname
  script_name procname
end

monitoring_metric "keystone-proc" do
  type "proc"
  proc_name "keystone"
  proc_regex platform_options["keystone_service"]
  alarms(:failure_min => 2.0)
end

directory "/etc/keystone" do
  action :create
  owner "keystone"
  group "keystone"
  mode "0700"
end

execute "keystone-manage db_sync" do
  user "keystone"
  group "keystone"
  command "keystone-manage db_sync"
  action :nothing
end

execute "keystone-manage pki_setup" do
  user "keystone"
  group "keystone"
  command "keystone-manage pki_setup"
  action :nothing
end

ks_service_bind = get_bind_endpoint("keystone", "service-api")
ks_admin_bind = get_bind_endpoint("keystone", "admin-api")
ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone-api", "keystone", "service-api")

template "/etc/keystone/keystone.conf" do
  source "keystone.conf.erb"
  owner "keystone"
  group "keystone"
  mode "0600"

  variables(
            :debug => node["keystone"]["debug"],
            :verbose => node["keystone"]["verbose"],
            :user => node["keystone"]["db"]["username"],
            :passwd => node["keystone"]["db"]["password"],
            :ip_address => ks_admin_bind["host"],
            :db_name => node["keystone"]["db"]["name"],
            :db_ipaddress => mysql_connect_ip,
            :service_port => ks_service_bind["port"],
            :admin_port => ks_admin_bind["port"],
            :admin_token => node["keystone"]["admin_token"],
            :use_syslog => node["keystone"]["syslog"]["use"],
            :log_facility => node["keystone"]["syslog"]["facility"],
            :auth_type => node["keystone"]["auth_type"],
            :ldap_options => node["keystone"]["ldap"]
            )
  notifies :run, resources(:execute => "keystone-manage db_sync"), :immediately
  # TODO (mattt): Need to file bug here as package installation on CentOS
  # doesn't run pki_setup
  if platform?(%w{redhat centos fedora scientific})
    notifies :run, resources(:execute => "keystone-manage pki_setup"), :immediately
  end
  notifies :restart, resources(:service => "keystone"), :immediately
end


file "/var/lib/keystone/keystone.db" do
  action :delete
end

#TODO(shep): this should probably be derived from keystone.users hash keys
node["keystone"]["tenants"].each do |tenant_name|
  ## Add openstack tenant ##
  keystone_tenant "Create '#{tenant_name}' Tenant" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token node["keystone"]["admin_token"]
    tenant_name tenant_name
    tenant_description "#{tenant_name} Tenant"
    tenant_enabled "1" # Not required as this is the default
    action :create
  end
end

## Add Roles ##
node["keystone"]["roles"].each do |role_key|
  keystone_role "Create '#{role_key.to_s}' Role" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token node["keystone"]["admin_token"]
    role_name role_key
    action :create
  end
end

node["keystone"]["users"].each do |username, user_info|
  keystone_user "Create '#{username}' User" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token node["keystone"]["admin_token"]
    user_name username
    user_pass user_info["password"]
    tenant_name user_info["default_tenant"]
    user_enabled "1" # Not required as this is the default
    action :create
  end

  user_info["roles"].each do |rolename, tenant_list|
    tenant_list.each do |tenantname|
      keystone_role "Grant '#{rolename}' Role to '#{username}' User in '#{tenantname}' Tenant" do
        auth_host ks_admin_endpoint["host"]
        auth_port ks_admin_endpoint["port"]
        auth_protocol ks_admin_endpoint["scheme"]
        api_ver ks_admin_endpoint["path"]
        auth_token node["keystone"]["admin_token"]
        user_name username
        role_name rolename
        tenant_name tenantname
        action :grant
      end
    end
  end

end

## Add Services ##

keystone_service "Create Identity Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token node["keystone"]["admin_token"]
  service_name "keystone"
  service_type "identity"
  service_description "Keystone Identity Service"
  action :create
end

## Add Endpoints ##

node.set["keystone"]["adminURL"] = ks_admin_endpoint["uri"]
node.set["keystone"]["internalURL"] = ks_service_endpoint["uri"]
node.set["keystone"]["publicURL"] = ks_service_endpoint["uri"]

Chef::Log.info "Keystone AdminURL: #{ks_admin_endpoint["uri"]}"
Chef::Log.info "Keystone InternalURL: #{ks_service_endpoint["uri"]}"
Chef::Log.info "Keystone PublicURL: #{ks_service_endpoint["uri"]}"

keystone_endpoint "Create Identity Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token node["keystone"]["admin_token"]
  service_type "identity"
  endpoint_region "RegionOne"
  endpoint_adminurl node["keystone"]["adminURL"]
  endpoint_internalurl node["keystone"]["internalURL"]
  endpoint_publicurl node["keystone"]["publicURL"]
  action :create
end


node["keystone"]["users"].each do |username, user_info|
  keystone_credentials "Create EC2 credentials for '#{username}' user" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token node["keystone"]["admin_token"]
    user_name username
    tenant_name user_info["default_tenant"]
  end
end

# Add keystone monitoring metrics
monitoring_metric "keystone" do
  keystone_admin_user = node["keystone"]["admin_user"]
  type "pyscript"
  script "keystone_plugin.py"
  options("Username" => keystone_admin_user,
          "Password" => node["keystone"]["users"][keystone_admin_user]["password"],
          "TenantName" => node["keystone"]["users"][keystone_admin_user]["default_tenant"],
          "AuthURL" => ks_service_endpoint["uri"])
end

include_recipe "keystone::keystoneclient-patch"
