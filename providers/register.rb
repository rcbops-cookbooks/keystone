#
# Cookbook Name:: keystone
# Provider:: register
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

action :create_service do
    # construct a HTTP object
    http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

    # Check to see if connection is http or https
    if new_resource.auth_protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(new_resource.auth_token)

    # Construct the extension path
    path = "/#{new_resource.api_ver}/OS-KSADM/services"

    # lookup service_uuid
    service_container = "OS-KSADM:services"
    service_key = "type"
    service_path = "/#{new_resource.api_ver}/OS-KSADM/services"
    service_uuid, service_error = _find_id(http, service_path, headers, service_container, service_key, new_resource.service_type)
    Chef::Log.error("There was an error looking up Service '#{new_resource.service_type}'") if service_error

    # See if the service exists yet
    unless service_uuid or service_error
        # Service does not exist yet
        payload = _build_service_object(new_resource.service_type, new_resource.service_name, new_resource.service_description)
        resp = http.send_request('POST', path, JSON.generate(payload), headers)
        if resp.is_a?(Net::HTTPOK)
            Chef::Log.info("Created service '#{new_resource.service_name}'")
            new_resource.updated_by_last_action(true)
        else
            Chef::Log.error("Unable to create service '#{new_resource.service_name}'")
            Chef::Log.error("Response Code: #{resp.code}")
            Chef::Log.error("Response Message: #{resp.message}")
            new_resource.updated_by_last_action(false)
        end
    else
        Chef::Log.info("Service Type '#{new_resource.service_type}' already exists.. Not creating.") if service_uuid
        Chef::Log.info("Service UUID: #{service_uuid}") if service_uuid
        Chef::Log.error("There was an error looking up '#{new_resource.role_name}'") if service_error
        new_resource.updated_by_last_action(false)
    end
end


action :delete_service do
    # construct a HTTP object
    http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

    # Check to see if connection is http or https
    if new_resource.auth_protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(new_resource.auth_token)

    # Construct the extension path
    path = "/#{new_resource.api_ver}/OS-KSADM/services"

    # lookup service_uuid
    service_container = "OS-KSADM:services"
    service_key = "type"
    service_path = "/#{new_resource.api_ver}/OS-KSADM/services"
    service_uuid, service_error = _find_id(http, service_path, headers, service_container, service_key, new_resource.service_type)
    Chef::Log.error("There was an error looking up Service '#{new_resource.service_type}'") if service_error

    # See if the service exists yet
    if service_uuid
        unless service_error
            path = "#{path}/#{service_uuid}"
            # Service does not exist yet
            #payload = _build_service_object(new_resource.service_type, new_resource.service_name, new_resource.service_description)
            #resp = http.send_request('DELETE', path, JSON.generate(payload), headers)
            resp = http.delete(path, headers)
            if resp.is_a?(Net::HTTPNoContent)
                Chef::Log.info("Deleted service '#{new_resource.service_name}'")
                new_resource.updated_by_last_action(true)
            else
                Chef::Log.error("Unable to delete service '#{new_resource.service_name}'")
                Chef::Log.error("Response Code: #{resp.code}")
                Chef::Log.error("Response Message: #{resp.message}")
                new_resource.updated_by_last_action(false)
            end
        end
    else
        Chef::Log.info("Service Type '#{new_resource.service_type}' does not exist.. Can't delete.") if not service_uuid
        Chef::Log.error("There was an error looking up '#{new_resource.role_name}'") if service_error
        new_resource.updated_by_last_action(false)
    end
end

action :create_endpoint do
    # construct a HTTP object
    http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

    # Check to see if connection is http or https
    if new_resource.auth_protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(new_resource.auth_token)

    # Construct the extension path
    path = "/#{new_resource.api_ver}/endpoints"

    # lookup service_uuid
    service_container = "OS-KSADM:services"
    service_key = "type"
    service_path = "/#{new_resource.api_ver}/OS-KSADM/services"
    service_uuid, service_error = _find_id(http, service_path, headers, service_container, service_key, new_resource.service_type)
    Chef::Log.error("There was an error looking up Service '#{new_resource.service_type}'") if service_error

    unless service_uuid or service_error
        Chef::Log.error("Unable to find service type '#{new_resource.service_type}'")
        new_resource.updated_by_last_action(false)
    end

    # Make sure this endpoint does not already exist
    resp = http.request_get(path, headers)
    if resp.is_a?(Net::HTTPOK)
        endpoint_exists = false
        data = JSON.parse(resp.body)
        data['endpoints'].each do |endpoint|
            if endpoint['service_id'] == service_uuid
                # Match found
                endpoint_exists = true
                break
            end
        end
        if endpoint_exists
            Chef::Log.info("Endpoint already exists for Service Type '#{new_resource.service_type}' already exists.. Not creating.")
            new_resource.updated_by_last_action(false)
        else
            payload = _build_endpoint_object(
                      new_resource.endpoint_region,
                      service_uuid,
                      new_resource.endpoint_publicurl,
                      new_resource.endpoint_internalurl,
                      new_resource.endpoint_adminurl)
            resp = http.send_request('POST', path, JSON.generate(payload), headers)
            if resp.is_a?(Net::HTTPOK)
                Chef::Log.info("Created endpoint for service type '#{new_resource.service_type}'")
                new_resource.updated_by_last_action(true)
            else
                Chef::Log.error("Unable to create endpoint for service type '#{new_resource.service_type}'")
                Chef::Log.error("Response Code: #{resp.code}")
                Chef::Log.error("Response Message: #{resp.message}")
                new_resource.updated_by_last_action(false)
            end
        end
    else
        Chef::Log.error("Unknown response from the Keystone Server")
        Chef::Log.error("Response Code: #{resp.code}")
        Chef::Log.error("Response Message: #{resp.message}")
        new_resource.updated_by_last_action(false)
    end
end


action :delete_endpoint do
    # construct a HTTP object
    http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

    # Check to see if connection is http or https
    if new_resource.auth_protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(new_resource.auth_token)

    # Construct the extension path
    path = "/#{new_resource.api_ver}/endpoints"

    # lookup service_uuid
    service_container = "OS-KSADM:services"
    service_key = "type"
    service_path = "/#{new_resource.api_ver}/OS-KSADM/services"
    service_uuid, service_error = _find_id(http, service_path, headers, service_container, service_key, new_resource.service_type)
    Chef::Log.error("There was an error looking up Service '#{new_resource.service_type}'") if service_error

    unless service_uuid or service_error
        Chef::Log.error("Unable to find service type '#{new_resource.service_type}'")
        new_resource.updated_by_last_action(false)
    end

    # lookup endpoint_uuid
    endpoint_container = "endpoints"
    endpoint_key = "service_id"
    endpoint_path = "/#{new_resource.api_ver}/endpoints"
    endpoint_uuid, endpoint_error = _find_id(http, endpoint_path, headers, endpoint_container, endpoint_key, service_uuid)
    Chef::Log.error("There was an error looking up endpoint for Service '#{new_resource.service_type}'") if endpoint_error
    Chef::Log.error("service_uuid is '#{service_uuid}'") if endpoint_error

    unless endpoint_uuid or endpoint_error
        Chef::Log.error("Unable to find endpoint for service type '#{new_resource.service_type}'")
        new_resource.updated_by_last_action(false)
    end


    # Make sure this endpoint does already exist
    resp = http.request_get(path, headers)
    if resp.is_a?(Net::HTTPOK)
        endpoint_exists = false
        data = JSON.parse(resp.body)
        data['endpoints'].each do |endpoint|
            if endpoint['service_id'] == service_uuid
                # Match found
                endpoint_exists = true
                break
            end
        end
        if endpoint_exists
            #Chef::Log.info("Endpoint already exists for Service Type '#{new_resource.service_type}' already exists.. Not creating.")
            #new_resource.updated_by_last_action(false)
            path = "#{path}/#{endpoint_uuid}"
            resp = http.delete(path, headers)
            if resp.is_a?(Net::HTTPNoContent)
                Chef::Log.info("deleted endpoint for service type '#{new_resource.service_type}'")
                new_resource.updated_by_last_action(true)
            else
                Chef::Log.error("Unable to delete endpoint for service type '#{new_resource.service_type}'")
                Chef::Log.error("Response Code: #{resp.code}")
                Chef::Log.error("Response Message: #{resp.message}")
                new_resource.updated_by_last_action(false)
            end
        else
            Chef::Log.info("Endpoint does not exist for Service Type '#{new_resource.service_type}'... Not attempting delete")
            new_resource.updated_by_last_action(false)

        end
    else
        Chef::Log.error("Unknown response from the Keystone Server")
        Chef::Log.error("Response Code: #{resp.code}")
        Chef::Log.error("Response Message: #{resp.message}")
        new_resource.updated_by_last_action(false)
    end
end

action :recreate_endpoint do
    # construct a HTTP object
    http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

    # Check to see if connection is http or https
    if new_resource.auth_protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(new_resource.auth_token)

    # Construct the extension path
    path = "/#{new_resource.api_ver}/endpoints"

    # lookup service_uuid
    service_container = "OS-KSADM:services"
    service_key = "type"
    service_path = "/#{new_resource.api_ver}/OS-KSADM/services"
    service_uuid, service_error = _find_id(http, service_path, headers, service_container, service_key, new_resource.service_type)
    Chef::Log.error("There was an error looking up Service '#{new_resource.service_type}'") if service_error

    unless service_uuid or service_error
        Chef::Log.error("Unable to find service type '#{new_resource.service_type}'")
        new_resource.updated_by_last_action(false)
    end

    # lookup current publicurl, internalurl, adminurl
    urls = {}
    ["publicurl", "internalurl", "adminurl"].each do |url|
        endpoint_container = "endpoints"
        endpoint_key = "service_id"
        endpoint_path = "/#{new_resource.api_ver}/endpoints"
        val, error = _find_value(http, endpoint_path, headers, endpoint_container, endpoint_key, service_uuid, url)
        Chef::Log.error("There was an error looking up endpoint for Service '#{new_resource.service_type}'") if error
        Chef::Log.error("service_uuid is '#{service_uuid}'") if error
        urls[url] = val
        unless url or error
            Chef::Log.error("Unable to find #{url} value for service type '#{new_resource.service_type}'")
            new_resource.updated_by_last_action(false)
        end
    end

    # get new publicurl, internalurl, adminurl
    new_urls = {}
    new_urls["publicurl"] = new_resource.endpoint_publicurl
    new_urls["internalurl"] = new_resource.endpoint_internalurl
    new_urls["adminurl"] = new_resource.endpoint_adminurl

    Chef::Log.debug("existing urls are: #{urls}")
    Chef::Log.debug("new urls would be: #{new_urls}")

    # test to see if our new values are different - if not, do nothing
    if urls == new_urls
        Chef::Log.info("Endpoints are already correct - nothing to do here")
    else
        # delete and recreate the endpoints

        # lookup parent endpoint_uuid
        endpoint_exists = false
        endpoint_container = "endpoints"
        endpoint_key = "service_id"
        endpoint_path = "/#{new_resource.api_ver}/endpoints"
        endpoint_uuid, endpoint_error = _find_id(http, endpoint_path, headers, endpoint_container, endpoint_key, service_uuid)
        Chef::Log.error("There was an error looking up endpoint for Service '#{new_resource.service_type}'") if endpoint_error
        Chef::Log.error("service_uuid is '#{service_uuid}'") if endpoint_error

        unless endpoint_uuid or endpoint_error
            Chef::Log.info("Unable to find endpoint for service type '#{new_resource.service_type}'")
        else
            endpoint_exists = true
        end

        # Make sure we have something to delete
        if endpoint_exists
            endpoint_path = "#{path}/#{endpoint_uuid}"
            resp = http.delete(endpoint_path, headers)
            if resp.is_a?(Net::HTTPNoContent)
                Chef::Log.info("deleted endpoint for service type '#{new_resource.service_type}'")
            else
                Chef::Log.error("Unable to delete endpoint for service type '#{new_resource.service_type}'")
                Chef::Log.error("Response Code: #{resp.code}")
                Chef::Log.error("Response Message: #{resp.message}")
                new_resource.updated_by_last_action(false)
            end
        else
            Chef::Log.info("Endpoint does not exist for Service Type '#{new_resource.service_type}'... Not attempting delete")
            new_resource.updated_by_last_action(false)
        end

        # and now create it with our new values
        payload = _build_endpoint_object(
                  new_resource.endpoint_region,
                  service_uuid,
                  new_resource.endpoint_publicurl,
                  new_resource.endpoint_internalurl,
                  new_resource.endpoint_adminurl)
        Chef::Log::debug("payload contains: #{payload}")
        Chef::Log::debug("path is: #{path}")
        resp = http.send_request('POST', path, JSON.generate(payload), headers)
        if resp.is_a?(Net::HTTPOK)
            Chef::Log.info("Created endpoint for service type '#{new_resource.service_type}'")
            new_resource.updated_by_last_action(true)
        else
            Chef::Log.error("Unable to create endpoint for service type '#{new_resource.service_type}'")
            Chef::Log.error("Response Code: #{resp.code}")
            Chef::Log.error("Response Message: #{resp.message}")
            new_resource.updated_by_last_action(false)
        end
    end
end

action :create_tenant do
    # construct a HTTP object
    http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

    # Check to see if connection is http or https
    if new_resource.auth_protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(new_resource.auth_token)

    # Construct the extension path
    path = "/#{new_resource.api_ver}/tenants"

    # lookup tenant_uuid
    tenant_container = "tenants"
    tenant_key = "name"
    tenant_path = "/#{new_resource.api_ver}/tenants"
    tenant_uuid, tenant_error = _find_id(http, tenant_path, headers, tenant_container, tenant_key, new_resource.tenant_name)
    Chef::Log.error("There was an error looking up Tenant '#{new_resource.tenant_name}'") if tenant_error

    unless tenant_uuid or tenant_error
        # Service does not exist yet
        payload = _build_tenant_object(new_resource.tenant_name, new_resource.service_description, new_resource.tenant_enabled)
        resp = http.send_request('POST', path, JSON.generate(payload), headers)
        if resp.is_a?(Net::HTTPOK)
            Chef::Log.info("Created tenant '#{new_resource.tenant_name}'")
            new_resource.updated_by_last_action(true)
        else
            Chef::Log.error("Unable to create tenant '#{new_resource.tenant_name}'")
            Chef::Log.error("Response Code: #{resp.code}")
            Chef::Log.error("Response Message: #{resp.message}")
            new_resource.updated_by_last_action(false)
        end
    else
        Chef::Log.info("Tenant '#{new_resource.tenant_name}' already exists.. Not creating.")
        Chef::Log.info("Tenant UUID: #{tenant_uuid}")
        Chef::Log.error("There was an error looking up '#{new_resource.role_name}'") if tenant_error
        new_resource.updated_by_last_action(false)
    end
end

action :create_role do
    # construct a HTTP object
    http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

    # Check to see if connection is http or https
    if new_resource.auth_protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(new_resource.auth_token)

    # Construct the extension path
    path = "/#{new_resource.api_ver}/OS-KSADM/roles"

    container = "roles"
    key = "name"

    # See if the role exists yet
    role_uuid, error = _find_id(http, path, headers, container, key, new_resource.role_name)
    unless role_uuid
        # role does not exist yet
        payload = _build_role_obj(new_resource.role_name)
        resp = http.send_request('POST', path, JSON.generate(payload), headers)
        if resp.is_a?(Net::HTTPOK)
            Chef::Log.info("Created Role '#{new_resource.role_name}'")
            new_resource.updated_by_last_action(true)
        else
            Chef::Log.error("Unable to create role '#{new_resource.role_name}'")
            Chef::Log.error("Response Code: #{resp.code}")
            Chef::Log.error("Response Message: #{resp.message}")
            new_resource.updated_by_last_action(false)
        end
    else
        Chef::Log.info("Role '#{new_resource.role_name}' already exists.. Not creating.") if error
        Chef::Log.info("Role UUID: #{role_uuid}")
        new_resource.updated_by_last_action(false)
    end
end

action :create_user do
    # construct a HTTP object
    http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

    # Check to see if connection is http or https
    if new_resource.auth_protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(new_resource.auth_token)

    # lookup tenant_uuid
    tenant_container = "tenants"
    tenant_key = "name"
    tenant_path = "/#{new_resource.api_ver}/tenants"
    tenant_uuid, tenant_error = _find_id(http, tenant_path, headers, tenant_container, tenant_key, new_resource.tenant_name)
    Chef::Log.error("There was an error looking up Tenant '#{new_resource.tenant_name}'") if tenant_error

    unless tenant_uuid
        Chef::Log.error("Unable to find tenant '#{new_resource.tenant_name}'")
        new_resource.updated_by_last_action(false)
    end

    # Construct the extension path using the found tenant_uuid
    path = "/#{new_resource.api_ver}/users"

    # Make sure this endpoint does not already exist
    resp = http.request_get("#{new_resource.api_ver}/tenants/#{tenant_uuid}/users", headers)
    if resp.is_a?(Net::HTTPOK)
        user_exists = false
        data = JSON.parse(resp.body)
        data['users'].each do |endpoint|
            if endpoint['name'] == new_resource.user_name
                # Match found
                user_exists = true
                break
            end
        end
        if user_exists
            Chef::Log.info("User '#{new_resource.user_name}' already exists for tenant '#{new_resource.tenant_name}'")
            new_resource.updated_by_last_action(false)
        else
            payload = _build_user_object(
                      tenant_uuid,
                      new_resource.user_name,
                      new_resource.user_pass,
                      new_resource.user_enabled)
            resp = http.send_request('POST', path, JSON.generate(payload), headers)
            if resp.is_a?(Net::HTTPOK)
                Chef::Log.info("Created user '#{new_resource.user_name}' for tenant '#{new_resource.tenant_name}'")
                new_resource.updated_by_last_action(true)
            else
                Chef::Log.error("Unable to create user '#{new_resource.user_name}' for tenant '#{new_resource.tenant_name}'")
                Chef::Log.error("Response Code: #{resp.code}")
                Chef::Log.error("Response Message: #{resp.message}")
                new_resource.updated_by_last_action(false)
            end
        end
    else
        Chef::Log.error("Unknown response from the Keystone Server")
        Chef::Log.error("Response Code: #{resp.code}")
        Chef::Log.error("Response Message: #{resp.message}")
        new_resource.updated_by_last_action(false)
    end
end

action :grant_role do
    # construct a HTTP object
    http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

    # Check to see if connection is http or https
    if new_resource.auth_protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(new_resource.auth_token)

    # lookup tenant_uuid
    tenant_container = "tenants"
    tenant_key = "name"
    tenant_path = "/#{new_resource.api_ver}/tenants"
    tenant_uuid, tenant_error = _find_id(http, tenant_path, headers, tenant_container, tenant_key, new_resource.tenant_name)
    Chef::Log.error("There was an error looking up Tenant '#{new_resource.tenant_name}'") if tenant_error

    # lookup user_uuid
    user_container = "users"
    user_key = "name"
    # user_path = "/#{new_resource.api_ver}/tenants/#{tenant_uuid}/users"
    user_path = "/#{new_resource.api_ver}/users"
    user_uuid, user_error = _find_id(http, user_path, headers, user_container, user_key, new_resource.user_name)
    Chef::Log.error("There was an error looking up User '#{new_resource.user_name}'") if user_error

    # lookup role_uuid
    role_container = "roles"
    role_key = "name"
    role_path = "/#{new_resource.api_ver}/OS-KSADM/roles"
    role_uuid, role_error = _find_id(http, role_path, headers, role_container, role_key, new_resource.role_name)
    Chef::Log.error("There was an error looking up Role '#{new_resource.role_name}'") if role_error

    Chef::Log.debug("Found Tenant UUID: #{tenant_uuid}")
    Chef::Log.debug("Found User UUID: #{user_uuid}")
    Chef::Log.debug("Found Role UUID: #{role_uuid}")

    # lookup roles assigned to user/tenant
    assigned_container = "roles"
    assigned_key = "name"
    assigned_path = "/#{new_resource.api_ver}/tenants/#{tenant_uuid}/users/#{user_uuid}/roles"
    assigned_role_uuid, assigned_error = _find_id(http, assigned_path, headers, assigned_container, assigned_key, new_resource.role_name)
    Chef::Log.error("There was an error looking up Assigned Role '#{new_resource.role_name}' for User '#{new_resource.user_name}' and Tenant '#{new_resource.tenant_name}'") if assigned_error

    error = (tenant_error or user_error or role_error or assigned_error)
    unless role_uuid == assigned_role_uuid or error
        # Construct the extension path
        path = "/#{new_resource.api_ver}/tenants/#{tenant_uuid}/users/#{user_uuid}/roles/OS-KSADM/#{role_uuid}"

        # needs a '' for the body, or it throws a 500
        resp = http.send_request('PUT', path, '', headers)
        if resp.is_a?(Net::HTTPOK)
            Chef::Log.info("Granted Role '#{new_resource.role_name}' to User '#{new_resource.user_name}' in Tenant '#{new_resource.tenant_name}'")
            new_resource.updated_by_last_action(true)
        else
            Chef::Log.error("Unable to grant role '#{new_resource.role_name}'")
            Chef::Log.error("Response Code: #{resp.code}")
            Chef::Log.error("Response Message: #{resp.message}")
            new_resource.updated_by_last_action(false)
        end
    else
        Chef::Log.info("Role '#{new_resource.role_name}' already exists.. Not granting.")
        Chef::Log.error("There was an error looking up '#{new_resource.role_name}'") if error
        new_resource.updated_by_last_action(false)
    end
end


private
def _find_id(http, path, headers, container, key, match_value)
    uuid = nil
    error = false
    resp = http.request_get(path, headers)
    if resp.is_a?(Net::HTTPOK)
        data = JSON.parse(resp.body)
        data[container].each do |obj|
            uuid = obj['id'] if obj[key] == match_value
            break if uuid
        end
    else
        Chef::Log.error("Unknown response from the Keystone Server")
        Chef::Log.error("Response Code: #{resp.code}")
        Chef::Log.error("Response Message: #{resp.message}")
        error = true
    end
    return uuid,error
end


#TODO(mancdaz): convert all lookups to use _find_value instead of _find_id
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
def _build_service_object(type, name, description)
    service_obj = Hash.new
    service_obj.store("type", type)
    service_obj.store("name", name)
    service_obj.store("description", description)
    ret = Hash.new
    ret.store("OS-KSADM:service", service_obj)
    return ret
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
def _build_tenant_object(name, description, enabled)
    tenant_obj = Hash.new
    tenant_obj.store("name", name)
    tenant_obj.store("description", description)
    tenant_obj.store("enabled", enabled)
    ret = Hash.new
    ret.store("tenant", tenant_obj)
    return ret
end


private
def _build_endpoint_object(region, service_uuid, publicurl, internalurl, adminurl)
    endpoint_obj = Hash.new
    endpoint_obj.store("adminurl", adminurl)
    endpoint_obj.store("internalurl", internalurl)
    endpoint_obj.store("publicurl", publicurl)
    endpoint_obj.store("service_id", service_uuid)
    endpoint_obj.store("region", region)
    ret = Hash.new
    ret.store("endpoint", endpoint_obj)
    return ret
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
    ret.store('user-agent', 'Chef keystone_register')
    return ret
end
