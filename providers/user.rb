#
# Cookbook Name:: keystone
# Provider:: user
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
    end

    # Build out the required header info
    headers = _build_headers(token)

    # lookup tenant_uuid
    tenant_container = "tenants"
    tenant_key = "name"
    tenant_path = "/#{api_ver}/tenants"
    tenant_uuid, tenant_error = _find_value(http, tenant_path, headers, tenant_container, tenant_key, tenant_name, 'id')
    Chef::Log.error("There was an error looking up Tenant '#{tenant_name}'") if tenant_error

    unless tenant_uuid
        Chef::Log.error("Unable to find tenant '#{tenant_name}'")
        new_resource.updated_by_last_action(false)
    end

    # Make sure this user does not already exist
    user_container = "users"
    user_key = "name"
    tenant_user_path = "#{api_ver}/tenants/#{tenant_uuid}/users"
    user_uuid, user_error = _find_value(http, tenant_user_path, headers, user_container, user_key, name, 'id')

    unless user_uuid or user_error
        path = "/#{api_ver}/users"
        payload = _build_user_object(tenant_uuid, name, pass, enabled)
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


private
def _find_value(http, path, headers, container, key, match_value, value)
    val = nil
    error = false
    resp = http.request_get(path, headers)
    if resp.is_a?(Net::HTTPOK)
        data = JSON.parse(resp.body)
        data[container].each do |obj|
            val = obj[value] if obj[key] == match_value
            break if val
        end
    else
        Chef::Log.error("Unknown response from the Keystone Server")
        Chef::Log.error("Response Code: #{resp.code}")
        Chef::Log.error("Response Message: #{resp.message}")
        error = true
    end
    return val,error
end


private
def _build_user_object(tenant_uuid, name, password, enabled)
    user_obj = Hash.new
    user_obj.store("tenantId", tenant_uuid)
    user_obj.store("name", name)
    user_obj.store("password", password)
    # Have to provide a null value for this because I dont want to have this in the LWRP
    user_obj.store("email", nil)
    user_obj.store("enabled", enabled)
    ret = Hash.new
    ret.store("user", user_obj)
    return ret
end


private
def _build_headers(token)
    ret = Hash.new
    ret.store('X-Auth-Token', token)
    ret.store('Content-type', 'application/json')
    ret.store('user-agent', 'Chef keystone_user')
    return ret
end
