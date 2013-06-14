#
# Cookbook Name:: keystone
# Recipe:: setup
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

# make sure we die early if there are keystone-setups other than us
if get_role_count("keystone-setup", false) > 0
  msg = "You can only have one node with the keystone-setup role"
  Chef::Application.fatal! msg
end

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "mysql::client"
include_recipe "mysql::ruby"
include_recipe "osops-utils"

# Allow for using a well known db password
ks_ns = "keystone"
if node["developer_mode"]
  node.set_unless[ks_ns]["db"]["password"] = "keystone"
  node.set_unless[ks_ns]["admin_token"] = "999888777666"
  node.set_unless[ks_ns]["users"]["monitoring"]["password"] = "monitoring"
else
  node.set_unless[ks_ns]["db"]["password"] = secure_password
  node.set_unless[ks_ns]["admin_token"] = secure_password
  node.set_unless[ks_ns]["users"]["monitoring"]["password"] = secure_password
end

#creates db and user, returns connection info, defined in osops-utils/libraries
mysql_info = create_db_and_user(
  "mysql",
  node["keystone"]["db"]["name"],
  node["keystone"]["db"]["username"],
  node["keystone"]["db"]["password"])
mysql_connect_ip = get_access_endpoint('mysql-master', 'mysql', 'db')["host"]


include_recipe "keystone::keystone-common"


execute "keystone-manage db_sync" do
  user "keystone"
  group "keystone"
  command "keystone-manage db_sync"
  action :run
end

# Setting attributes inside ruby_block means they'll get set at run time
# rather than compile time; these files do not exist at compile time when chef
# is first run.
ruby_block "store key and certs in attributes" do
  block do
    if node["keystone"]["pki"]["enabled"] == true
      node.set_unless["keystone"]["pki"]["key"] = File.read("/etc/keystone/ssl/private/signing_key.pem")
      node.set_unless["keystone"]["pki"]["cert"] = File.read("/etc/keystone/ssl/certs/signing_cert.pem")
      node.set_unless["keystone"]["pki"]["cacert"] = File.read("/etc/keystone/ssl/certs/ca.pem")
    end
  end
end

ks_api_role = "keystone-api"
ks_ns = "keystone"
ks_admin_endpoint = get_access_endpoint(ks_api_role, ks_ns, "admin-api")
ks_service_endpoint = get_access_endpoint(ks_api_role, ks_ns, "service-api")

# TODO(shep): this should probably be derived from keystone.users hash keys
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
    tenant_enabled true # Not required as this is the default
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

# FIXME: Workaround for https://bugs.launchpad.net/keystone/+bug/1176270
keystone_role "Get Member role-id" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token node["keystone"]["admin_token"]
    action :get_member_role_id
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
    user_enabled true # Not required as this is the default
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
