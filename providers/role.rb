#
# Cookbook Name:: keystone
# Provider:: role
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
    token = new_resource.auth_token
    api_ver = new_resource.api_ver
    role_name = new_resource.role_name

    # construct a HTTP object
    http = Net::HTTP.new(host, port)

    # Check to see if connection is http or https
    if protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(token)

    # Construct the extension path
    path = "/#{api_ver}/OS-KSADM/roles"

    container = "roles"
    key = "name"

    # See if the role exists yet
    role_uuid, role_error = _find_value(http, path, headers, container, key, role_name, 'id')
    unless role_uuid or role_error
        # role does not exist yet
        payload = _build_role_obj(role_name)
        resp = http.send_request('POST', path, JSON.generate(payload), headers)
        if resp.is_a?(Net::HTTPOK)
            Chef::Log.info("Created Role '#{role_name}'")
            new_resource.updated_by_last_action(true)
        else
            Chef::Log.error("Unable to create role '#{role_name}'")
            Chef::Log.error("Response Code: #{resp.code}")
            Chef::Log.error("Response Message: #{resp.message}")
            new_resource.updated_by_last_action(false)
        end
    else
        Chef::Log.info("Role '#{role_name}' already exists.. Not creating.") if role_uuid
        Chef::Log.info("Role UUID: #{role_uuid}") if role_uuid
        Chef::Log.error("There was an error looking up role '#{role_name}'") if role_error
        new_resource.updated_by_last_action(false)
    end
end

action :grant do
    host = new_resource.auth_host
    port = new_resource.auth_port
    protocol = new_resource.auth_protocol
    api_ver = new_resource.api_ver
    token = new_resource.auth_token
    role_name = new_resource.role_name
    tenant_name = new_resource.tenant_name
    user_name = new_resource.user_name

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

    # lookup user_uuid
    user_container = "users"
    user_key = "name"
    # user_path = "/#{new_resource.api_ver}/tenants/#{tenant_uuid}/users"
    user_path = "/#{api_ver}/users"
    user_uuid, user_error = _find_value(http, user_path, headers, user_container, user_key, user_name, 'id')
    Chef::Log.error("There was an error looking up User '#{user_name}'") if user_error

    # lookup role_uuid
    role_container = "roles"
    role_key = "name"
    role_path = "/#{new_resource.api_ver}/OS-KSADM/roles"
    role_uuid, role_error = _find_value(http, role_path, headers, role_container, role_key, role_name, 'id')
    Chef::Log.error("There was an error looking up Role '#{role_name}'") if role_error

    Chef::Log.debug("Found Tenant UUID: #{tenant_uuid}")
    Chef::Log.debug("Found User UUID: #{user_uuid}")
    Chef::Log.debug("Found Role UUID: #{role_uuid}")

    # lookup roles assigned to user/tenant
    assigned_container = "roles"
    assigned_key = "name"
    assigned_path = "/#{api_ver}/tenants/#{tenant_uuid}/users/#{user_uuid}/roles"
    assigned_role_uuid, assigned_error = _find_value(http, assigned_path, headers, assigned_container, assigned_key, role_name, 'id')
    Chef::Log.error("There was an error looking up Assigned Role '#{role_name}' for User '#{user_name}' and Tenant '#{tenant_name}'") if assigned_error

    error = (tenant_error or user_error or role_error or assigned_error)
    unless role_uuid == assigned_role_uuid or error
        # Construct the extension path
        path = "/#{api_ver}/tenants/#{tenant_uuid}/users/#{user_uuid}/roles/OS-KSADM/#{role_uuid}"

        # needs a '' for the body, or it throws a 500
        resp = http.send_request('PUT', path, '', headers)
        if resp.is_a?(Net::HTTPOK)
            Chef::Log.info("Granted Role '#{role_name}' to User '#{user_name}' in Tenant '#{tenant_name}'")
            new_resource.updated_by_last_action(true)
        else
            Chef::Log.error("Unable to grant role '#{role_name}'")
            Chef::Log.error("Response Code: #{resp.code}")
            Chef::Log.error("Response Message: #{resp.message}")
            new_resource.updated_by_last_action(false)
        end
    else
        Chef::Log.info("Role '#{role_name}' already exists.. Not granting.")
        Chef::Log.error("There was an error looking up '#{role_name}'") if error
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
def _build_role_obj(name)
    role_obj = Hash.new
    role_obj.store("name", name)
    ret = Hash.new
    ret.store("role", role_obj)
    return ret
end


private
def _build_headers(token)
    ret = Hash.new
    ret.store('X-Auth-Token', token)
    ret.store('Content-type', 'application/json')
    ret.store('user-agent', 'Chef keystone_role')
    return ret
end
