#
# Cookbook Name:: keystone
# Recipe:: keystone-common
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

# fixup the keystone.log ownership if it exists
file "/var/log/keystone/keystone.log" do
  owner "keystone"
  group "keystone"
  mode "0600"
  only_if { ::File.exists?("/var/log/keystone/keystone.log") }
end

platform_options = node["keystone"]["platform"]

package_list = platform_options["keystone_packages"] +
  platform_options["keystone_ldap_packages"] +
  platform_options["mysql_python_packages"]

package_list.each do |pkg|
  package pkg do
    if node["osops"]["do_package_upgrades"]
      action :upgrade
    else
      action :install
    end
    options platform_options["package_options"]
  end
end

execute "Keystone: sleep" do
  command "sleep 10s"
  action :nothing
end

service "keystone" do
  service_name platform_options["keystone_service"]
  supports :status => true, :restart => true
  action [:enable]
  notifies :run, "execute[Keystone: sleep]", :immediately
end

directory "/etc/keystone" do
  action :create
  owner "keystone"
  group "keystone"
  mode "0700"
end

execute "keystone-manage pki_setup" do
  user "keystone"
  group "keystone"
  command "keystone-manage pki_setup"
  action :nothing
end

ks_admin_bind = get_bind_endpoint("keystone", "admin-api")
ks_service_bind = get_bind_endpoint("keystone", "service-api")
settings = get_settings_by_role("keystone-setup", "keystone")
mysql_info = get_access_endpoint("mysql-master", "mysql", "db")

# only bind to 0.0.0.0 if we're not using openstack-ha w/ a keystone-admin-api VIP,
# otherwise HAProxy will fail to start when trying to bind to keystone VIP
ha_role = "openstack-ha"
vip_key = "vips.keystone-admin-api"
if get_role_count(ha_role) > 0 and rcb_safe_deref(node, vip_key)
  ip_address = ks_admin_bind["host"]
else
  ip_address = "0.0.0.0"
end

# Setup db_info hash for use in the template
db_info = {
  "user" => settings["db"]["username"],
  "pass" => settings["db"]["password"],
  "name" => settings["db"]["name"],
  "ipaddress" => mysql_info["host"] }

# Setup SSL if "scheme" is set to https
if ks_service_bind["scheme"] == "https" or ks_admin_bind["scheme"] == "https"
  include_recipe "keystone::keystone-ssl"
else
  apache_site "openstack-keystone" do
    enable false
    notifies :run, "execute[restore-selinux-context]", :immediately
    notifies :restart, "service[apache2]", :immediately
  end
  service "keystone" do
    action [ :enable, :restart ]
  end
end

template "/etc/keystone/keystone.conf" do
  source "keystone.conf.erb"
  owner "keystone"
  group "keystone"
  mode "0600"

  variables(
    :debug => settings["debug"],
    :verbose => settings["verbose"],
    :db_info => db_info,
    :ip_address => ip_address,
    :service_port => ks_service_bind["port"],
    :admin_port => ks_admin_bind["port"],
    :admin_token => settings["admin_token"],
    :member_role_id => node["keystone"]["member_role_id"],
    :auth_type => settings["auth_type"],
    :ldap_options => settings["ldap"],
    :pki_token_signing => settings["pki"]["enabled"]
  )
  # The pki_setup runs via postinst on Ubuntu, but doesn't run via package
  # installation on CentOS.
  if platform?(%w{redhat centos fedora scientific})
    notifies :run, "execute[keystone-manage pki_setup]", :immediately
  end
  # FIXME: Workaround for https://bugs.launchpad.net/keystone/+bug/1176270
  subscribes :create, "keystone_role[Get Member role-id]", :delayed
  unless ks_service_bind["scheme"] == "https" or ks_admin_bind["scheme"] == "https"
    notifies :restart, "service[keystone]", :immediately
  else
    notifies :restart, "service[apache2]", :immediately
  end
end

file "/var/lib/keystone/keystone.db" do
  action :delete
end
