module RCB_keystone_helpers

  def build_credentials_obj(tenant_uuid)
    ret = Hash.new
    ret.store("tenant_id", tenant_uuid)
    return ret
  end

  def find_value(http, path, headers, container, key, match_value, value)
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
    return val, error
  end

  def build_endpoint_object(region, service_uuid, publicurl, internalurl, adminurl)
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

  def build_headers(token)
    ret = Hash.new
    ret.store('X-Auth-Token', token)
    ret.store('Content-type', 'application/json')
    ret.store('user-agent', 'Chef keystone_endpoint')
    return ret
  end

  def build_role_obj(name)
    role_obj = Hash.new
    role_obj.store("name", name)
    ret = Hash.new
    ret.store("role", role_obj)
    return ret
  end

  def build_service_object(type, name, description)
    service_obj = Hash.new
    service_obj.store("type", type)
    service_obj.store("name", name)
    service_obj.store("description", description)
    ret = Hash.new
    ret.store("OS-KSADM:service", service_obj)
    return ret
  end

  def build_tenant_object(name, description, enabled)
    tenant_obj = Hash.new
    tenant_obj.store("name", name)
    tenant_obj.store("description", description)
    tenant_obj.store("enabled", enabled)
    ret = Hash.new
    ret.store("tenant", tenant_obj)
    return ret
  end

  def build_user_object(tenant_uuid, name, password, enabled)
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

end
class Chef::Provider
  include RCB_keystone_helpers
end
