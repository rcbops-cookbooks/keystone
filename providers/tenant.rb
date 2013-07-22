#
# Cookbook Name:: keystone
# Provider:: tenant
#
# Copyright 2012-2013, Rackspace US, Inc.
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


action :create do
  host = new_resource.auth_host
  port = new_resource.auth_port
  protocol = new_resource.auth_protocol
  api_ver = new_resource.api_ver
  token = new_resource.auth_token
  name = new_resource.tenant_name
  desc = new_resource.tenant_description
  enabled = new_resource.tenant_enabled

  # construct a HTTP object
  http = Net::HTTP.new(host, port)

  # Check to see if connection is http or https
  if protocol == "https"
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  # Build out the required header info
  headers = build_headers(token)

  # Construct the extension path
  path = "/#{api_ver}/tenants"

  # lookup tenant_uuid
  tenant_container = "tenants"
  tenant_key = "name"
  tenant_path = "/#{api_ver}/tenants"
  tenant_uuid, tenant_error = find_value(http, tenant_path, headers, tenant_container, tenant_key, name, 'id')
  Chef::Log.error("There was an error looking up Tenant '#{name}'") if tenant_error

  unless tenant_uuid or tenant_error
    # Tenant does not exist yet
    payload = build_tenant_object(name, desc, enabled)
    resp = http.send_request('POST', path, JSON.generate(payload), headers)
    if resp.is_a?(Net::HTTPOK)
      Chef::Log.info("Created tenant '#{name}'")
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.error("Unable to create tenant '#{name}'")
      Chef::Log.error("Response Code: #{resp.code}")
      Chef::Log.error("Response Message: #{resp.message}")
      new_resource.updated_by_last_action(false)
    end
  else
    Chef::Log.info("Tenant '#{name}' already exists.. Not creating.")
    Chef::Log.info("Tenant UUID: #{tenant_uuid}")
    Chef::Log.error("There was an error looking up '#{name}'") if tenant_error
    new_resource.updated_by_last_action(false)
  end
end

action :delete do
  # TODO(shep): Need to implement delete action
  Chef::Log.info("Keystone_Tenant action delete, has not been implemented yet")
  new_resource.updated_by_last_action(false)
end
