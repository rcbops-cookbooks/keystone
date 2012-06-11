#
# Cookbook Name:: keystone
# Recipe:: server-monitoring
#
# Copyright 2009, Rackspace Hosting, Inc.
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

ks_service_endpoint = get_bind_endpoint("keystone", "service-api")
keystone = get_settings_by_roles("keystone", "keystone")
keystone_admin_user = keystone["admin_user"]
keystone_admin_password = keystone["users"][keystone_admin_user]["password"]
keystone_admin_tenant = keystone["users"][keystone_admin_user]["default_tenant"]

########################################
# BEGIN COLLECTD SECTION
# TODO(shep): This needs to be encased in an if block for the collectd_enabled environment toggle

include_recipe "collectd-graphite::collectd-client"

cookbook_file File.join(node['collectd']['plugin_dir'], "keystone_plugin.py") do
  source "keystone_plugin.py"
  owner "root"
  group "root"
  mode "0644"
end

collectd_python_plugin "keystone_plugin" do
  options(
    "Username"=>keystone_admin_user,
    "Password"=>keystone_admin_password,
    "TenantName"=>keystone_admin_tenant,
    "AuthURL"=>ks_service_endpoint["uri"]
  )
end
########################################


########################################
# BEGIN MONIT SECTION
# TODO(shep): This needs to be encased in an if block for the monit_enabled environment toggle

include_recipe "monit::server"
platform_options = node["nova"]["platform"]

monit_procmon "keystone" do
  process_name "keystone-all"
  start_cmd platform_options["monit_commands"]["start"]
  stop_cmd platform_options["monit_commands"]["stop"]
end
########################################
