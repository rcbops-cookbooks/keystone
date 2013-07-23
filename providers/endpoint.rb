#
# Cookbook Name:: keystone
# Provider:: endpoint
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
  token = new_resource.auth_token
  api_ver = new_resource.api_ver
  svc_type = new_resource.service_type
  region = new_resource.endpoint_region
  admin_url = new_resource.endpoint_adminurl
  internal_url = new_resource.endpoint_internalurl
  public_url = new_resource.endpoint_publicurl

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
  path = "/#{api_ver}/endpoints"

  # lookup service_uuid
  service_container = "OS-KSADM:services"
  service_key = "type"
  service_path = "/#{api_ver}/OS-KSADM/services"
  service_uuid, service_error = find_value(http, service_path, headers, service_container, service_key, svc_type, 'id')
  Chef::Log.error("There was an error looking up Service '#{svc_type}'") if service_error

  unless service_uuid or service_error
    Chef::Log.error("Unable to find service type '#{svc_type}'")
    new_resource.updated_by_last_action(false)
  end

  # Make sure this endpoint does not already exist
  endpoint_container = "endpoints"
  endpoint_key = "service_id"
  endpoint_uuid, endpoint_error = find_value(http, path, headers, endpoint_container, endpoint_key, service_uuid, 'id')

  unless endpoint_uuid or endpoint_error
    payload = build_endpoint_object(
      region,
      service_uuid,
      public_url,
      internal_url,
      admin_url)
    resp = http.send_request('POST', path, JSON.generate(payload), headers)
    if resp.is_a?(Net::HTTPOK)
      Chef::Log.info("Created endpoint for service type '#{svc_type}'")
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.error("Unable to create endpoint for service type '#{svc_type}'")
      Chef::Log.error("Response Code: #{resp.code}")
      Chef::Log.error("Response Message: #{resp.message}")
      new_resource.updated_by_last_action(false)
    end
  else
    Chef::Log.info("Endpoint already exists for Service Type '#{svc_type}' already exists.. Not creating.") if endpoint_uuid
    Chef::Log.info("Endpoint UUID: #{endpoint_uuid}") if endpoint_uuid
    Chef::Log.error("There was an error looking up endpoint for '#{svc_type}'") if endpoint_error
    new_resource.updated_by_last_action(false)
  end
end


action :delete do
  #TODO(shep): needs to be rewritten like :create
  # construct a HTTP object
  http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

  # Check to see if connection is http or https
  if new_resource.auth_protocol == "https"
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  # Build out the required header info
  headers = build_headers(new_resource.auth_token)

  # Construct the extension path
  path = "/#{new_resource.api_ver}/endpoints"

  # lookup service_uuid
  service_container = "OS-KSADM:services"
  service_key = "type"
  service_path = "/#{new_resource.api_ver}/OS-KSADM/services"
  service_uuid, service_error = find_value(http, service_path, headers, service_container, service_key, new_resource.service_type, 'id')
  Chef::Log.error("There was an error looking up Service '#{new_resource.service_type}'") if service_error

  unless service_uuid or service_error
    Chef::Log.error("Unable to find service type '#{new_resource.service_type}'")
    new_resource.updated_by_last_action(false)
  end

  # lookup endpoint_uuid
  endpoint_container = "endpoints"
  endpoint_key = "service_id"
  endpoint_path = "/#{new_resource.api_ver}/endpoints"
  endpoint_uuid, endpoint_error = find_value(http, endpoint_path, headers, endpoint_container, endpoint_key, service_uuid, 'id')
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

action :recreate do
  # construct a HTTP object
  http = Net::HTTP.new(new_resource.auth_host, new_resource.auth_port)

  # Check to see if connection is http or https
  if new_resource.auth_protocol == "https"
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  # Build out the required header info
  headers = build_headers(new_resource.auth_token)

  # Construct the extension path
  path = "/#{new_resource.api_ver}/endpoints"

  # lookup service_uuid
  service_container = "OS-KSADM:services"
  service_key = "type"
  service_path = "/#{new_resource.api_ver}/OS-KSADM/services"
  service_uuid, service_error = find_value(http, service_path, headers, service_container, service_key, new_resource.service_type, 'id')
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
    val, error = find_value(http, endpoint_path, headers, endpoint_container, endpoint_key, service_uuid, url)
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
    endpoint_uuid, endpoint_error = find_value(http, endpoint_path, headers, endpoint_container, endpoint_key, service_uuid, 'id')
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
    payload = build_endpoint_object(
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
