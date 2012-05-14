#
# Cookbook Name:: keystone
# Recipe:: server
#
# Copyright 2009, Rackspace Hosting, Inc.
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

include_recipe "mysql::client"

# Distribution specific settings go here
if platform?(%w{fedora})
  # Fedora
  mysql_python_package = "MySQL-python"
  keystone_package = "openstack-keystone"
  keystone_service = keystone_package
  keystone_package_options = ""
else
  # All Others (right now Debian and Ubuntu)
  mysql_python_package="python-mysqldb"
  keystone_package = "keystone"
  keystone_service = keystone_package
  keystone_package_options = "-o Dpkg::Options::='--force-confold' --force-yes"
end

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
  # Lookup mysql ip address
  mysql_server, something, arbitary_value = Chef::Search::Query.new.search(:node, "roles:mysql-master AND chef_environment:#{node.chef_environment}")
  if mysql_server.length > 0
    Chef::Log.info("keystone::server.rb/mysql: using search")
    db_ip_address = mysql_server[0]['mysql']['bind_address']
    db_root_password = mysql_server[0]['mysql']['server_root_password']
  else
    Chef::Log.info("keystone::server.rb/mysql: NOT using search")
    db_ip_address = node['mysql']['bind_address']
    db_root_password = node['mysql']['server_root_password']
  end
end

connection_info = {:host => db_ip_address, :username => "root", :password => db_root_password}

mysql_database "create keystone database" do
  connection connection_info
  database_name node["keystone"]["db"]
  action :create
end

mysql_database_user node["keystone"]["db_user"] do
  connection connection_info
  password node["keystone"]["db_passwd"]
  action :create
end

mysql_database_user node["keystone"]["db_user"] do
  connection connection_info
  password node["keystone"]["db_passwd"]
  database_name node["keystone"]["db"]
  host '%'
  privileges [:all]
  action :grant 
end

##### NOTE #####
# https://bugs.launchpad.net/ubuntu/+source/keystone/+bug/931236
################

package mysql_python_package do
  action :install
end

package keystone_package do
  action :upgrade
  options keystone_package_options
end

execute "Keystone: sleep" do
  command "sleep 10s"
  action :nothing
end

service keystone_service do
  supports :status => true, :restart => true
  action [ :enable, :start ]
  notifies :run, resources(:execute => "Keystone: sleep"), :immediately
end

directory "/etc/keystone" do
  action :create
  owner "root"
  group "root"
  mode "0755"
  not_if do 
    File.exists?("/etc/keystone")
  end
end

file "/var/lib/keystone/keystone.db" do
  action :delete
end

execute "keystone-manage db_sync" do
  command "keystone-manage db_sync"
  action :nothing
end

template "/etc/keystone/keystone.conf" do
  source "keystone.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
            :debug => node["keystone"]["debug"],
            :verbose => node["keystone"]["verbose"],
            :user => node["keystone"]["db_user"],
            :passwd => node["keystone"]["db_passwd"],
            :ip_address => node["keystone"]["api_ipaddress"],
            :db_name => node["keystone"]["db"],
            :db_ipaddress => db_ip_address,
            :service_port => node["keystone"]["service_port"],
            :admin_port => node["keystone"]["admin_port"],
            :admin_token => node["keystone"]["admin_token"]
            )
  notifies :run, resources(:execute => "keystone-manage db_sync"), :immediately
end

template "/etc/keystone/logging.conf" do
  source "keystone-logging.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => keystone_service), :immediately
end

#token = node["keystone"]["admin_token"]
#admin_url = "http://#{node["keystone"]["api_ipaddress"]}:#{node["keystone"]["admin_port"]}/v2.0"
#keystone_cmd = "keystone --token #{token} --endpoint #{admin_url}"

node["keystone"]["tenants"].each do |tenant_name|
  ## Add openstack tenant ##
  keystone_register "Register '#{tenant_name}' Tenant" do
    auth_host node["keystone"]["api_ipaddress"]
    auth_port node["keystone"]["admin_port"]
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token node["keystone"]["admin_token"]
    tenant_name tenant_name
    tenant_description "#{tenant_name} Tenant"
    tenant_enabled "true" # Not required as this is the default
    action :create_tenant
  end
end

## Add Roles ##
node["keystone"]["roles"].each do |role_key|
  keystone_register "Register '#{role_key.to_s}' Role" do
  auth_host node["keystone"]["api_ipaddress"]
    auth_port node["keystone"]["admin_port"]
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token node["keystone"]["admin_token"]
    role_name role_key
    action :create_role
  end
end

node["keystone"]["users"].each do |username, user_info|
  keystone_register "Register '#{username}' User" do
    auth_host node["keystone"]["api_ipaddress"]
    auth_port node["keystone"]["admin_port"]
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token node["keystone"]["admin_token"]
    user_name username
    user_pass user_info["password"]
    tenant_name user_info["default_tenant"]
    user_enabled "true" # Not required as this is the default
    action :create_user
  end

  user_info["roles"].each do |rolename, tenant_list|
    tenant_list.each do |tenantname|
      keystone_register "Grant '#{rolename}' Role to '#{username}' User in '#{tenantname}' Tenant" do
        auth_host node["keystone"]["api_ipaddress"]
        auth_port node["keystone"]["admin_port"]
        auth_protocol "http"
        api_ver "/v2.0"
        auth_token node["keystone"]["admin_token"]
        user_name username
        role_name rolename
        tenant_name tenantname
        action :grant_role
      end
    end

  end
end

## Add Services ##

keystone_register "Register Identity Service" do
  auth_host node["keystone"]["api_ipaddress"]
  auth_port node["keystone"]["admin_port"]
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token node["keystone"]["admin_token"]
  service_name "keystone"
  service_type "identity"
  service_description "Keystone Identity Service"
  action :create_service
end

## Add Endpoints ##

node["keystone"]["adminURL"] = "http://#{node["keystone"]["api_ipaddress"]}:#{node["keystone"]["admin_port"]}/v2.0"
node["keystone"]["internalURL"] = "http://#{node["keystone"]["api_ipaddress"]}:#{node["keystone"]["service_port"]}/v2.0"
node["keystone"]["publicURL"] = node["keystone"]["internalURL"]

Chef::Log.info "Keystone AdminURL: #{node["keystone"]["adminURL"]}"
Chef::Log.info "Keystone InternalURL: #{node["keystone"]["internalURL"]}"
Chef::Log.info "Keystone PublicURL: #{node["keystone"]["publicURL"]}"

keystone_register "Register Identity Endpoint" do
  auth_host node["keystone"]["api_ipaddress"]
  auth_port node["keystone"]["admin_port"]
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token node["keystone"]["admin_token"]
  service_type "identity"
  endpoint_region "RegionOne"
  endpoint_adminurl node["keystone"]["adminURL"]
  endpoint_internalurl node["keystone"]["internalURL"]
  endpoint_publicurl node["keystone"]["publicURL"]
  action :create_endpoint
end


node["keystone"]["users"].each do |username, user_info|
  keystone_credentials "Create EC2 credentials for '#{username}' user" do
    auth_host node["keystone"]["api_ipaddress"]
    auth_port node["keystone"]["admin_port"]
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token node["keystone"]["admin_token"]
    user_name username
    tenant_name user_info["default_tenant"]
  end
end
