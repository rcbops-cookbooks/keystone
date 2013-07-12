#
# Cookbook Name:: keystone
# Recipe:: keystone-ssl
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
include_recipe "apache2"
include_recipe "apache2::mod_wsgi"
include_recipe "apache2::mod_rewrite"
include_recipe "osops-utils::mod_ssl"
include_recipe "osops-utils::ssl_packages"

# Remove monit conf file if it exists
if node.attribute?"monit"
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

cookbook_file "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["admin-api"]["cert_file"]}" do
  source "keystone_admin.pem"
  mode 0644
  owner "root"
  group "root"
  notifies :run, "execute[restore-selinux-context]", :immediately
end

cookbook_file "#{node["keystone"]["ssl"]["dir"]}/private/#{node["keystone"]["services"]["admin-api"]["key_file"]}" do
  source "keystone_admin.key"
  mode 0644
  owner "root"
  group grp
  notifies :run, "execute[restore-selinux-context]", :immediately
end

cookbook_file "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["service-api"]["cert_file"]}" do
  source "keystone_service.pem"
  mode 0644
  owner "root"
  group "root"
  notifies :run, "execute[restore-selinux-context]", :immediately
end

cookbook_file "#{node["keystone"]["ssl"]["dir"]}/private/#{node["keystone"]["services"]["service-api"]["key_file"]}" do
  source "keystone_service.key"
  mode 0644
  owner "root"
  group grp
  notifies :run, "execute[restore-selinux-context]", :immediately
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

# Get the IP to bind to, "*" if only 1 node
ks_admin_bind = get_bind_endpoint("keystone", "admin-api")
ks_service_bind = get_bind_endpoint("keystone", "service-api")

ha_role = "openstack-ha"
vip_key = "vips.keystone-admin-api"
if get_role_count(ha_role) > 0 and rcb_safe_deref(node, vip_key)
  admin_ip = ks_admin_bind["host"]
  service_ip = ks_service_bind["host"]
else
  admin_ip = "*"
  service_ip = "*"
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
    :service_port => node["keystone"]["services"]["service-api"]["port"],
    :service_cert_file => "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["service-api"]["cert_file"]}",
    :service_key_file => "#{node["keystone"]["ssl"]["dir"]}/private/#{node["keystone"]["services"]["service-api"]["key_file"]}",
    :service_wsgi_file  => "#{node["apache"]["dir"]}/wsgi/#{node["keystone"]["services"]["service-api"]["wsgi_file"]}",
    :admin_ip => admin_ip,
    :admin_port => node["keystone"]["services"]["admin-api"]["port"],
    :admin_cert_file => "#{node["keystone"]["ssl"]["dir"]}/certs/#{node["keystone"]["services"]["admin-api"]["cert_file"]}",
    :admin_key_file => "#{node["keystone"]["ssl"]["dir"]}/private/#{node["keystone"]["services"]["admin-api"]["key_file"]}",
    :admin_wsgi_file => "#{node["apache"]["dir"]}/wsgi/#{node["keystone"]["services"]["admin-api"]["wsgi_file"]}"
  )
  notifies :run, "execute[restore-selinux-context]", :immediately
  notifies :reload, "service[apache2]", :delayed
end

apache_site "openstack-keystone" do
  enable true
  notifies :run, "execute[restore-selinux-context]", :immediately
  notifies :restart, "service[apache2]", :immediately
  notifies :run, "execute[Keystone: sleep]", :immediately
end
