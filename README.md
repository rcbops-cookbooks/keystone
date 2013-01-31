Description
===========

This cookbook installs the OpenStack Identity Service (codename: keystone) from packages, creating default user, tenant, and roles. It also registers the identity service and identity endpoint.

http://keystone.openstack.org/

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use)

Platform
--------

* Ubuntu-12.04
* Fedora-17

Cookbooks
---------

The following cookbooks are dependencies:

* database
* mysql

Resources/Providers
===================

These resources provide an abstraction layer for interacting with the keystone server's API, allowing for other nodes to register any required users, tenants, roles, services, or endpoints.

Tenant
------

Handles creating and deleting of Keystone Tenants.

### ACTIONS

- :create - Create a Keystone Tenant
- :delete - Delete a Keystone Tenant

### Required Attributes

- auth_protocol: Required communication protocol with Keystone server
  - Acceptable values are [ "http", "https" ]
- auth_host: Keystone server IP Address
- auth_port: Port Keystone server is listening on
- api_ver: API Version for Keystone server
  - Accepted values are [ "/v2.0" ]
- auth_token: Auth Token for communication with Keystone server
- tenant_name: Name of tenant to create
- tenant_description: Description of tenant to create
- tenant_enabled: Enable or Disable tenant
  - Accepted values are [ "true", "false" ]
    - Default is "true"
 
### Example

    # Create 'openstack' tenant
    keystone_tenant "Create 'openstack' Tenant" do
      auth_host "192.168.1.10"
      auth_port "35357"
      auth_protocol "http"
      api_ver "/v2.0"
      auth_token "123456789876"
      tenant_name "openstack"
      tenant_description "Default Tenant"
      tenant_enabled "true" # Not required as this is the default
      action :create
    end

User
----

Handles creating and deleting of Keystone Users.

### ACTIONS

- :create - Create a Keystone Tenant
- :delete - Delete a Keystone Tenant

### Required Attributes

- auth_protocol: Required communication protocol with Keystone server
  - Acceptable values are [ "http", "https" ]
- auth_host: Keystone server IP Address
- auth_port: Port Keystone server is listening on
- api_ver: API Version for Keystone server
  - Accepted values are [ "/v2.0" ]
- auth_token: Auth Token for communication with Keystone server
- user_name: Name of user account to create
- user_pass: Password for the user account
- user_enabled: Enable or Disable user
  - Accepted values are [ "true", "false" ]
    - Default is "true"
- tenant_name: Name of tenant to create user in

### Example

    # Create 'admin' user
    keystone_user "Create 'admin' User" do
      auth_host "192.168.1.10"
      auth_port "35357"
      auth_protocol "http"
      api_ver "/v2.0"
      auth_token "123456789876"
      tenant_name "openstack"
      user_name "admin"
      user_pass "secrete"
      user_enabled "true" # Not required as this is the default
      action :create
    end

Role
----

Handles creating, deleting and granting of Keystone Roles.

### ACTIONS

- :create - Create a Keystone Tenant
- :delete - Delete a Keystone Tenant

### Required Attributes

- auth_protocol: Required communication protocol with Keystone server
  - Acceptable values are [ "http", "https" ]
- auth_host: Keystone server IP Address
- auth_port: Port Keystone server is listening on
- api_ver: API Version for Keystone server
  - Accepted values are [ "/v2.0" ]
- auth_token: Auth Token for communication with Keystone server
- role_name: Name of the role to create

### :grant Specific Attributes

- user_name: User name to grant the role to
- tenant_name: Name of tenant to grant role in

### Examples

    # Create 'admin' role
    keystone_role "Create 'admin' Role" do
      auth_host "192.168.1.10"
      auth_port "35357"
      auth_protocol "http"
      api_ver "/v2.0"
      auth_token "123456789876"
      role_name "admin"
      action :create
    end


    # Grant 'admin' role to 'admin' user in the 'openstack' tenant
    keystone_role "Grant 'admin' Role to 'admin' User" do
      auth_host "192.168.1.10"
      auth_port "35357"
      auth_protocol "http"
      api_ver "/v2.0"
      auth_token "123456789876"
      tenant_name "openstack"
      user_name "admin"
      role_name "admin"
      action :grant
    end

Service
-------

Handles creating and deleting of Keystone Services.

### Actions

- :create - Create a Keystone Service
- :delete - Delete a Keystone Service

### Required Attributes

- auth_protocol: Required communication protocol with Keystone server
  - Acceptable values are [ "http", "https" ]
- auth_host: Keystone server IP Address
- auth_port: Port Keystone server is listening on
- api_ver: API Version for Keystone server
  - Accepted values are [ "/v2.0" ]
- auth_token: Auth Token for communication with Keystone server
- service_name: Name of service
- service_description: Description of service
- service_type: Type of service to create
  - Accepted values are [ "image", "identity", "network", "compute", "storage", "ec2", "volume" ]

### Example

    # Create 'identity' service
    keystone_service "Create Identity Service" do
      auth_host "192.168.1.10"
      auth_port "35357"
      auth_protocol "http"
      api_ver "/v2.0"
      auth_token "123456789876"
      service_name "keystone"
      service_type "identity"
      service_description "Keystone Identity Service"
      action :create
    end

Endpoint
--------

Handles creating, deleting, and recreating of Keystone Endpoints.

### Actions

- :create - Create a Keystone Endpoint
- :delete - Delete a Keystone Endpoint
- :recreate - Recreate a Keystone Endpoint

### Required Attributes

- auth_protocol: Required communication protocol with Keystone server
  - Acceptable values are [ "http", "https" ]
- auth_host: Keystone server IP Address
- auth_port: Port Keystone server is listening on
- api_ver: API Version for Keystone server
  - Accepted values are [ "/v2.0" ]
- auth_token: Auth Token for communication with Keystone server
- endpoint_region: Default value is "RegionOne"
- endpoint_adminurl: URL to admin endpoint (using admin port)
- endpoint_internalurl: URL to service endpoint (using service port)
- endpoint_publicurl: URL to public endpoint
  - Default is same as endpoint_internalURL
- service_type: Type of service to create endpoint for
  - Accepted values are [ "image", "identity", "network", "compute", "storage", "ec2", "volume" ]

### Example

    # Create 'identity' endpoint
    keystone_endpoint "Register Identity Endpoint" do
      auth_host "192.168.1.10"
      auth_port "35357"
      auth_protocol "http"
      api_ver "/v2.0"
      auth_token "123456789876"
      service_type "identity"
      endpoint_region "RegionOne"
      endpoint_adminurl "http://192.168.1.10:35357/v2.0"
      endpoint_internalurl "http://192.168.1.10:5001/v2.0"
      endpoint_publicurl "http://1.2.3.4:5001/v2.0"
      action :create
    end

credentials
-----------

Create EC2 credentials for a given user in the specified tenant

### Actions

- :create_ec2: create EC2 credentials

### General Attributes

- auth_protocol: Required communication protocol with Keystone server. Acceptable values are [ "http", "https" ]
- auth_host: Keystone server IP Address
- auth_port: Port Keystone server is listening on
- api_ver: API Version for Keystone server
 - Accepted values are [ "/v2.0" ]
- auth_token: Auth Token for communication with Keystone server

### :create_ec2 Specific Attributes

- user_name: User name to grant the credentials for
- tenant_name: Tenant name to grant the credentials in

### Examples

    keystone_credentials "Create EC2 credentials for 'admin' user" do
      auth_host "192.168.1.10"
      auth_port "35357"
      auth_protocol "http"
      api_ver "/v2.0"
      auth_token "123456789876"
      user_name "admin"
      tenant_name "openstack"
    end

Recipes
=======

default
-------

The default recipe will install the Keystone Server

server
------

Installs the Keystone Server

Data Bags
=========

Attributes 
==========

* `keystone["db"]["name"]` - Name of keystone database
* `keystone["db"]["username"]` - Username for keystone database access
* `keystone["db"][""password"]` - Password for keystone database access
* `keystone["verbose"]` - Enables/disables verbose output for the keystone services
* `keystone["debug"]` - Enables/disables debug output for keystone API server
* `keystone["auth_type"]` - Which backend type to use
* `keystone["ldap"]` - See `LDAP Support` section below for descriptions
* `keystone["services"]["admin-api"]["scheme"]` - Protocol to use when connecting to keystone
* `keystone["services"]["admin-api"]["network"]` - Network to connect to the admin-api over
* `keystone["services"]["admin-api"]["port"]` - Port for the admin-api service to listen on
* `keystone["services"]["admin-api"]["path"]` - Keystone version path
* `keystone["services"]["service-api"]["scheme"]` - Protocol to use when connecting to the service-api
* `keystone["services"]["service-api"]["network"]` - Network to connect to the service-api over
* `keystone["services"]["service-api"]["port"]` - Port for the service-api service to listen on
* `keystone["services"]["service-api"]["path"]` - Keystone version path
* `keystone["syslog"]["use"]` - Enables/disables syslog
* `keystone["syslog"]["facility"]` - Which syslog facility to log to
* `keysotne["syslog"]["config_facility"]` - 
* `keystone["roles"]` - Array of roles to create
* `keystone["tenants"]` - Array of tenants to create
* `keystone["admin_user"]` - Which user is designated as the "admin user"
* `keystone["users"]` - Hash of users to create.
* `keystone["config"]["log_verbosity"]` - Logging verbosity.  Valid options are DEBUG, INFO, WARNING, ERROR, CRITICAL.  Default is INFO

LDAP Support
=============
Begininng with the folsom version of the cookbooks we have added support for using LDAP as a keystone backend. In order to enable this functionality the following attributes must be set, in your chef environment, to match your ldap schema.

Base Configuration
-----------
* default["keystone"]["auth_type"] == "ldap"
    - set to sql by default
* default["keystone"]["ldap"]["url"] = """
    - the address/name of the ldap server
* default["keystone"]["ldap"]["tree_dn"] = ""
    - the toplevel tree distinguished name.
* default["keystone"]["ldap"]["user"] = ""
    - a user with administrative privileges to ldap
* default["keystone"]["ldap"]["password"] = ""
    - the password for the above user.
* default["keystone"]["ldap"]["suffix"] = ""
    - the ldap suffix (dc=example, dc=com)
* default["keystone"]["ldap"]["use_dumb_member"] = "false"


User Configuration
-----------

* default["keystone"]["ldap"]["user_tree_dn"] = ""
    - the distinguished name of the user tree (e.g. ou=Users,dc=example,dc=com)
* default["keystone"]["ldap"]["user_objectclass"] = "inetOrgPerson"
    - the objectclass for users created by keystone. Should match common ldap schema, inetOrgPerson by default.
* default["keystone"]["ldap"]["user_id_attribute"] = "cn"
    - the user id attribute for users created by keystone.Should match common ldap schema, cn by default.
* default["keystone"]["ldap"]["user_name_attribute"] = "sn"
    - the user name attribute for users created by keystone. Should match common ldap schema, sn by default.

Role Configuration
------------------
* default["keystone"]["ldap"]["role_tree_dn"] = ""
    - the distinguished name of the user tree (e.g. ou=Roles,dc=example,dc=com)
* default["keystone"]["ldap"]["role_objectclass"] = "organizationalRole"
    - the objectclass for roles created by keystone. Should match common ldap schema, organizationalRole by default.
* default["keystone"]["ldap"]["role_id_attribute"] = "cn"
    - the role id attribute for roles created by keystone. Should match common ldap schema, cn by default.
* default["keystone"]["ldap"]["role_member_attribute"] = "roleOccupant"
    - the attribute for a member of a role. Should match common ldap schema, roleOccupant by default.

Tenant Configuration
---------------------------
* default["keystone"]["ldap"]["tenant_tree_dn"] = ""
    - the distinguished name of the tenant tree (e.g. ou=Groups,dc=example,dc=com)
* default["keystone"]["ldap"]["tenant_objectclass"] = "groupOfNames"
    - the objectclass for the tenants created by keystone. Should match common ldap schema, groupOfNames by default.
* default["keystone"]["ldap"]["tenant_id_attribute"] = "cn"
    - the tenant id attribute for tenants created by keystone. Should match common ldap schema, cn by default.
* default["keystone"]["ldap"]["tenant_member_attribute"] = "member"
    - the tenant member attribute for tenants created by keystone. Should match common ldap schema, member by default.
* default["keystone"]["ldap"]["tenant_name_attribute"] = "ou"
    - the tenant name attribute for tenants creatsd by keystone. Should match common ldap schema, ou by default.

Usage
=====

License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@RACKSPACE.COM>)  
Author:: Darren Birkett (<Darren.Birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@RACKSPACE.COM>)  

Copyright 2012, Rackspace US, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

