#
# Cookbook Name:: keystone
# Recipe:: keystone-ssl
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
include_recipe "apache2"
include_recipe "apache2::mod_wsgi"
include_recipe "apache2::mod_rewrite"
include_recipe "osops-utils::mod_ssl"
include_recipe "osops-utils::ssl_packages"

# Remove monit conf file if it exists
if node.attribute? "monit"
  if node["monit"].attribute?"conf.d_dir"
    file "#{node['monit']['conf.d_dir']}/keystone.conf" do
      action :delete
      notifies :reload, "service[monit]", :immediately
    end
  end
end

# setup cert files
case node["platform"]
when "ubuntu", "debian"
  grp = "ssl-cert"
else
  grp = "root"
end

#admin API
cookbook_file "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["admin-api"]["cert_file"]}" do
  source "keystone_admin.pem"
  mode 0644
  owner "root"
  group "root"
end
cookbook_file "#{node["keystone"]["ssl"]["dir"]}/private/#{node["keystone"]["services"]["admin-api"]["key_file"]}" do
  source "keystone_admin.key"
  mode 0644
  owner "root"
  group grp
end
unless node["keystone"]["services"]["admin-api"]["chain_file"].nil?
  cookbook_file "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["admin-api"]["chain_file"]}" do
    source node["keystone"]["services"]["admin-api"]["chain_file"]
    mode 0644
    owner "root"
    group "root"
  end
end

#Service API
cookbook_file "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["service-api"]["cert_file"]}" do
  source "keystone_service.pem"
  mode 0644
  owner "root"
  group "root"
end
cookbook_file "#{node["keystone"]["ssl"]["dir"]}/private/#{node["keystone"]["services"]["service-api"]["key_file"]}" do
  source "keystone_service.key"
  mode 0644
  owner "root"
  group grp
end
unless node["keystone"]["services"]["service-api"]["chain_file"].nil?
  cookbook_file "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["service-api"]["chain_file"]}" do
    source node["keystone"]["services"]["service-api"]["chain_file"]
    mode 0644
    owner "root"
    group "root"
  end
end

#Internal URI
cookbook_file "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["internal-api"]["cert_file"]}" do
  source "keystone_internal.pem"
  mode 0644
  owner "root"
  group "root"
end
cookbook_file "#{node["keystone"]["ssl"]["dir"]}/private/#{node["keystone"]["services"]["internal-api"]["key_file"]}" do
  source "keystone_internal.key"
  mode 0644
  owner "root"
  group grp
end
unless node["keystone"]["services"]["internal-api"]["chain_file"].nil?
  cookbook_file "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["internal-api"]["chain_file"]}" do
    source node["keystone"]["services"]["internal-api"]["chain_file"]
    mode 0644
    owner "root"
    group "root"
  end
end

# setup wsgi file

directory "#{node["apache"]["dir"]}/wsgi" do
  action :create
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "#{node["apache"]["dir"]}/wsgi/#{node["keystone"]["services"]["admin-api"]["wsgi_file"]}" do
  source "keystone_modwsgi.py"
  mode 0644
  owner "root"
  group "root"
end

cookbook_file "#{node["apache"]["dir"]}/wsgi/#{node["keystone"]["services"]["service-api"]["wsgi_file"]}" do
  source "keystone_modwsgi.py"
  mode 0644
  owner "root"
  group "root"
end

cookbook_file "#{node["apache"]["dir"]}/wsgi/#{node["keystone"]["services"]["internal-api"]["wsgi_file"]}" do
  source "keystone_modwsgi.py"
  mode 0644
  owner "root"
  group "root"
end
# Get the IP to bind to, "*" if only 1 node
ks_admin_bind = get_bind_endpoint("keystone", "admin-api")
ks_service_bind = get_bind_endpoint("keystone", "service-api")
ks_internal_bind = get_bind_endpoint("keystone", "internal-api")

ha_role = "openstack-ha"
vip_key = "vips.keystone-admin-api"
if get_role_count(ha_role) > 0 and rcb_safe_deref(node, vip_key)
  admin_ip = ks_admin_bind["host"]
  service_ip = ks_service_bind["host"]
  internal_ip = ks_internal_bind["host"]
else
  admin_ip = "*"
  service_ip = "*"
end

# Admin API
unless node["keystone"]["services"]["admin-api"].attribute?"cert_override"
  admin_cert_location = "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["admin-api"]["cert_file"]}"
else
  admin_cert_location = node["keystone"]["services"]["admin-api"]["cert_override"]
end
unless node["keystone"]["services"]["admin-api"].attribute?"key_override"
  admin_key_location = "#{node["keystone"]["ssl"]["dir"]}/private/#{node["keystone"]["services"]["admin-api"]["key_file"]}"
else
  admin_key_location = node["keystone"]["services"]["admin-api"]["key_override"]
end
unless node["keystone"]["services"]["admin-api"]["chain_file"].nil?
  admin_chain_location = "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["admin-api"]["chain_file"]}"
else
  admin_chain_location = "donotset"
end

# Service API
unless node["keystone"]["services"]["service-api"].attribute?"cert_override"
  service_cert_location = "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["service-api"]["cert_file"]}"
else
  service_cert_location = node["keystone"]["services"]["service-api"]["cert_override"]
end
unless node["keystone"]["services"]["service-api"].attribute?"key_override"
  service_key_location = "#{node["keystone"]["ssl"]["dir"]}/private/#{node["keystone"]["services"]["service-api"]["key_file"]}"
else
  service_key_location = node["keystone"]["services"]["service-api"]["key_override"]
end
unless node["keystone"]["services"]["service-api"]["chain_file"].nil?
  service_chain_location = "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["service-api"]["chain_file"]}"
else
  service_chain_location = "donotset"
end

# Internal API
unless node["keystone"]["services"]["internal-api"].attribute?"cert_override"
  internal_cert_location = "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["service-api"]["cert_file"]}"
else
  internal_cert_location = node["keystone"]["services"]["internal-api"]["cert_override"]
end
unless node["keystone"]["services"]["internal-api"].attribute?"key_override"
  internal_key_location = "#{node["keystone"]["ssl"]["dir"]}/private/#{node["keystone"]["services"]["internal-api"]["key_file"]}"
else
  internal_key_location = node["keystone"]["services"]["internal-api"]["key_override"]
end
unless node["keystone"]["services"]["internal-api"]["chain_file"].nil?
  internal_chain_location = "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["internal-api"]["chain_file"]}"
else
  internal_chain_location = "donotset"
end

template value_for_platform(
  ["ubuntu", "debian", "fedora"] => {
    "default" => "#{node["apache"]["dir"]}/sites-available/openstack-keystone"
  },
  "fedora" => {
    "default" => "#{node["apache"]["dir"]}/vhost.d/openstack-keystone"
  },
  ["redhat", "centos"] => {
    "default" => "#{node["apache"]["dir"]}/conf.d/openstack-keystone"
  },
  "default" => {
    "default" => "#{node["apache"]["dir"]}/openstack-keystone"
  }
) do
  source "keystone_ssl_vhost.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :service_ip => service_ip,
    :service_scheme => node["keystone"]["services"]["service-api"]["scheme"],
    :service_port => node["keystone"]["services"]["service-api"]["port"],
    :service_cert_file => service_cert_location,
    :service_key_file => service_key_location,
    :service_chain_file => service_chain_location,
    :service_wsgi_file  => "#{node["apache"]["dir"]}/wsgi/#{node["keystone"]["services"]["service-api"]["wsgi_file"]}",
    :admin_ip => admin_ip,
    :admin_scheme => node["keystone"]["services"]["admin-api"]["scheme"],
    :admin_port => node["keystone"]["services"]["admin-api"]["port"],
    :admin_cert_file => admin_cert_location,
    :admin_key_file => admin_key_location,
    :admin_chain_file => admin_chain_location,
    :admin_wsgi_file => "#{node["apache"]["dir"]}/wsgi/#{node["keystone"]["services"]["admin-api"]["wsgi_file"]}",
    :internal_scheme => node["keystone"]["services"]["internal-api"]["scheme"],
    :internal_ip => internal_ip || service_ip,
    :internal_port => node["keystone"]["services"]["internal-api"]["port"],
    :internal_cert_file => internal_cert_location,
    :internal_key_file => internal_key_location,
    :internal_chain_file => internal_chain_location,
    :internal_wsgi_file  => "#{node["apache"]["dir"]}/wsgi/#{node["keystone"]["services"]["internal-api"]["wsgi_file"]}"
  )
  notifies :run, "execute[Keystone: sleep]", :immediately
end

apache_site "openstack-keystone" do
  enable true
end

service "apache2" do
  action :restart
end

