# Cookbook Name:: nova
# Recipe:: nova-scheduler-patch
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

include_recipe "osops-utils"

template "/usr/share/pyshared/keystone/common/config.py" do
  source "patches/ldap_user_enabled_default_config.py.1:2013.1-0ubuntu1~cloud0.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, "service[keystone]", :immediately
  only_if { ::Chef::Recipe::Patch.check_package_version("keystone", "1:2013.1-0ubuntu1~cloud0", node) }
end
