#
# Cookbook Name:: keystone
# Provider:: service
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
    svc_type = new_resource.service_type
    svc_name = new_resource.service_name
    svc_desc = new_resource.service_description

    # construct a HTTP object
    http = Net::HTTP.new(host, port)

    # Check to see if connection is http or https
    if protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(token)

    # Construct the extension path
    path = "/#{api_ver}/OS-KSADM/services"

    # lookup service_uuid
    service_container = "OS-KSADM:services"
    service_key = "type"
    service_path = "/#{api_ver}/OS-KSADM/services"
    service_uuid, service_error = _find_value(http, service_path, headers, service_container, service_key, svc_type, 'id')
    Chef::Log.error("There was an error looking up Service '#{svc_type}'") if service_error

    # See if the service exists yet
    unless service_uuid or service_error
        # Service does not exist yet
        payload = _build_service_object(svc_type, svc_name, svc_desc)
        resp = http.send_request('POST', path, JSON.generate(payload), headers)
        if resp.is_a?(Net::HTTPOK)
            Chef::Log.info("Created service '#{svc_name}'")
            new_resource.updated_by_last_action(true)
        else
            Chef::Log.error("Unable to create service '#{svc_name}'")
            Chef::Log.error("Response Code: #{resp.code}")
            Chef::Log.error("Response Message: #{resp.message}")
            new_resource.updated_by_last_action(false)
        end
    else
        Chef::Log.info("Service Type '#{svc_type}' already exists.. Not creating.") if service_uuid
        Chef::Log.info("Service UUID: #{service_uuid}") if service_uuid
        Chef::Log.error("There was an error looking up '#{svc_type}'") if service_error
        new_resource.updated_by_last_action(false)
    end
end


action :delete do
    host = new_resource.auth_host
    port = new_resource.auth_port
    protocol = new_resource.auth_protocol
    token = new_resource.auth_token
    api_ver = new_resource.api_ver
    svc_type = new_resource.service_type
    svc_name = new_resource.service_name
    svc_desc = new_resource.service_description

    # construct a HTTP object
    http = Net::HTTP.new(host, port)

    # Check to see if connection is http or https
    if protocol == "https"
        http.use_ssl = true
    end

    # Build out the required header info
    headers = _build_headers(token)

    # Construct the extension path
    path = "/#{api_ver}/OS-KSADM/services"

    # lookup service_uuid
    service_container = "OS-KSADM:services"
    service_key = "type"
    service_path = "/#{api_ver}/OS-KSADM/services"
    service_uuid, service_error = _find_value(http, service_path, headers, service_container, service_key, svc_type, 'id')
    Chef::Log.error("There was an error looking up Service '#{svc_type}'") if service_error

    # See if the service exists yet
    if service_uuid
        unless service_error
            path = "#{path}/#{service_uuid}"
            resp = http.delete(path, headers)
            if resp.is_a?(Net::HTTPNoContent)
                Chef::Log.info("Deleted service '#{svc_name}'")
                new_resource.updated_by_last_action(true)
            else
                Chef::Log.error("Unable to delete service '#{svc_name}'")
                Chef::Log.error("Response Code: #{resp.code}")
                Chef::Log.error("Response Message: #{resp.message}")
                new_resource.updated_by_last_action(false)
            end
        end
    else
        Chef::Log.info("Service Type '#{svc_type}' does not exist.. Can't delete.") if not service_uuid
        Chef::Log.error("There was an error looking up '#{svc_type}'") if service_error
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
def _build_headers(token)
    ret = Hash.new
    ret.store('X-Auth-Token', token)
    ret.store('Content-type', 'application/json')
    ret.store('user-agent', 'Chef keystone_service')
    return ret
end
