#
# Cookbook Name:: nova
# Recipe::keystoneclient-patch
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

include_recipe "osops-utils"

# https://bugs.launchpad.net/python-keystoneclient/+bug/1074784
# https://review.openstack.org/#/c/15410/
# Fix keystoneclient so swift works against Rackspace Cloud Files
template "/usr/share/pyshared/keystoneclient/v2_0/client.py" do
  source "patches/client.py.1:0.1.3.37+git201210301431~precise-0ubuntu1"
  owner "root"
  group "root"
  mode "0644"
  only_if { ::Chef::Recipe::Patch.check_package_version("python-keystoneclient","1:0.1.3.37+git201210301431~precise-0ubuntu1",node) }
end
