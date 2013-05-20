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

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "osops-utils"

include_recipe "keystone::keystone-common"

platform_options = node["keystone"]["platform"]

keystone = get_settings_by_role("keystone-setup", "keystone")

%w{ssl ssl/certs}.each do |dir|
  directory "/etc/keystone/#{dir}" do
    action :create
    owner  "keystone"
    group  "keystone"
    mode   "0755"
  end
end

directory "/etc/keystone/ssl/private" do
  action :create
  owner  "keystone"
  group  "keystone"
  mode   "0700"
end

if node["keystone"]["pki"]["enabled"] == true
  file "/etc/keystone/ssl/private/signing_key.pem" do
    owner   "keystone"
    group   "keystone"
    mode    "0400"
    content keystone["pki"]["key"]
  end

  file "/etc/keystone/ssl/certs/signing_cert.pem" do
    owner   "keystone"
    group   "keystone"
    mode    "0644"
    content keystone["pki"]["cert"]
  end

  file "/etc/keystone/ssl/certs/ca.pem" do
    owner   "keystone"
    group   "keystone"
    mode    "0444"
    content keystone["pki"]["cacert"]
  end
end

ks_api_role = "keystone-api"
ks_ns = "keystone"
ks_admin_endpoint = get_access_endpoint(ks_api_role, ks_ns, "admin-api")
ks_service_endpoint = get_access_endpoint(ks_api_role, ks_ns, "service-api")

## Add Services ##
keystone_service "Create Identity Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
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
  auth_token keystone["admin_token"]
  service_type "identity"
  endpoint_region "RegionOne"
  endpoint_adminurl node["keystone"]["adminURL"]
  endpoint_internalurl node["keystone"]["internalURL"]
  endpoint_publicurl node["keystone"]["publicURL"]
  action :create
end

# TODO(shep): this could probably come from the search result (keystone)
node["keystone"]["users"].each do |username, user_info|
  keystone_credentials "Create EC2 credentials for '#{username}' user" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token keystone["admin_token"]
    user_name username
    tenant_name user_info["default_tenant"]
  end
end

include_recipe "keystone::keystoneclient-patch"
