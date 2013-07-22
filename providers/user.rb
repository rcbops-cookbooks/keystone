#
# Cookbook Name:: keystone
# Provider:: user
#
# Copyright 2012-2013, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

action :create do
  host = new_resource.auth_host
  port = new_resource.auth_port
  protocol = new_resource.auth_protocol
  api_ver = new_resource.api_ver
  token = new_resource.auth_token
  tenant_name = new_resource.tenant_name
  name = new_resource.user_name
  pass = new_resource.user_pass
  enabled = new_resource.user_enabled

  # construct a HTTP object
  http = Net::HTTP.new(host, port)

  # Check to see if connection is http or https
  if protocol == "https"
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  # Build out the required header info
  headers = build_headers(token)

  # lookup tenant_uuid
  tenant_container = "tenants"
  tenant_key = "name"
  tenant_path = "/#{api_ver}/tenants"
  tenant_uuid, tenant_error = find_value(http, tenant_path, headers, tenant_container, tenant_key, tenant_name, 'id')
  Chef::Log.error("There was an error looking up Tenant '#{tenant_name}'") if tenant_error
  Chef::Log.fatal(tenant_error)


  unless tenant_uuid
    Chef::Log.error("Unable to find tenant '#{tenant_name}'")
    new_resource.updated_by_last_action(false)
  end

  # Make sure this user does not already exist
  user_container = "users"
  user_key = "name"
  tenant_user_path = "#{api_ver}/tenants/#{tenant_uuid}/users"
  user_uuid, user_error = find_value(http, tenant_user_path, headers, user_container, user_key, name, 'id')

  unless user_uuid or user_error
    path = "/#{api_ver}/users"
    payload = build_user_object(tenant_uuid, name, pass, enabled)
    resp = http.send_request('POST', path, JSON.generate(payload), headers)
    if resp.is_a?(Net::HTTPOK)
      Chef::Log.info("Created user '#{name}' for tenant '#{tenant_name}'")
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.error("Unable to create user '#{name}' for tenant '#{tenant_name}'")
      Chef::Log.error("Response Code: #{resp.code}")
      Chef::Log.error("Response Message: #{resp.message}")
      new_resource.updated_by_last_action(false)
    end
  else
    Chef::Log.info("User '#{name}' already exists for Tenant '#{tenant_name}'.. Not creating.") if user_uuid
    Chef::Log.info("User UUID: #{user_uuid}") if user_uuid
    Chef::Log.error("There was an error looking up user '#{name}' for tenant '#{tenant_name}'") if user_error
    new_resource.updated_by_last_action(false)
  end
end
