########################################################################
# Toggles - These can be overridden at the environment level
default["developer_mode"] = false  # we want secure passwords by default
########################################################################

# Adding these as blank
# this needs to be here for the initial deep-merge to work
default["credentials"]["EC2"]["admin"]["access"] = ""                       # node_attribute
default["credentials"]["EC2"]["admin"]["secret"] = ""                       # node_attribute

default["keystone"]["db"]["name"] = "keystone"                              # node_attribute
default["keystone"]["db"]["username"] = "keystone"                          # node_attribute
# Replacing with OpenSSL::Password in recipes/server.rb
# default["keystone"]["db"]["password"] = "keystone"

default["keystone"]["verbose"] = "False"                                    # node_attribute
default["keystone"]["debug"] = "False"                                      # node_attribute

# Auth type = sql or ldap
default["keystone"]["auth_type"] == "sql"				    # node_attribute

# ldap - base configuration
default["keystone"]["ldap"]["url"] = ""					    
default["keystone"]["ldap"]["tree_dn"] = ""
default["keystone"]["ldap"]["user"] = ""
default["keystone"]["ldap"]["password"] = ""
default["keystone"]["ldap"]["backend_entities"] = ['Tenant', 'User', 'UserRoleAssociation', 'Role'] 
default["keystone"]["ldap"]["suffix"] = ""
default["keystone"]["ldap"]["user_dumb_member"] = "False"

# ldap - User tree setup, dependant on ldap schema
default["keystone"]["ldap"]["user_tree_dn"] = ""
default["keystone"]["ldap"]["user_objectclass"] = "inetOrgPerson"
default["keystone"]["ldap"]["user_id_attribute"] = "cn"
default["keystone"]["ldap"]["user_name_attribute"] = "sn"

# ldap - Role tree setup, dependant on ldap schema. Can also use keystone db to manage roles
default["keystone"]["ldap"]["role_tree_dn"] = ""
default["keystone"]["ldap"]["role_objectclass"] = "organizationalRole"
default["keystone"]["ldap"]["role_id_attribute"] = "cn"
default["keystone"]["ldap"]["role_member_attribute"] = "roleOccupant"

# ldap - Tenant tree setup, dependant on ldap schema. Can also use keystone db to manage tenants
default["keystone"]["ldap"]["tenant_tree_dn"] = ""
default["keystone"]["ldap"]["tenant_objectclass"] = "groupOfNames"
default["keystone"]["ldap"]["tenant_id_attribute"] = "cn"
default["keystone"]["ldap"]["tenant_member_attribute"] = "member"
default["keystone"]["ldap"]["tenant_name_attribute"] = "ou"

# new endpoint location stuff
default["keystone"]["services"]["admin-api"]["scheme"] = "http"             # node_attribute
default["keystone"]["services"]["admin-api"]["network"] = "nova"            # node_attribute
default["keystone"]["services"]["admin-api"]["port"] = "35357"              # node_attribute
default["keystone"]["services"]["admin-api"]["path"] = "/v2.0"              # node_attribute

default["keystone"]["services"]["service-api"]["scheme"] = "http"           # node_attribute
default["keystone"]["services"]["service-api"]["network"] = "public"        # node_attribute
default["keystone"]["services"]["service-api"]["port"] = "5000"             # node_attribute
default["keystone"]["services"]["service-api"]["path"] = "/v2.0"            # node_attribute

# Logging stuff
default["keystone"]["syslog"]["use"] = true                                 # node_attribute
default["keystone"]["syslog"]["facility"] = "LOG_LOCAL3"                    # node_attribute
default["keystone"]["syslog"]["config_facility"] = "local3"                 # node_attribute

# default["keystone"]["roles"] = [ "admin", "Member", "KeystoneAdmin", "KeystoneServiceAdmin", "sysadmin", "netadmin" ]
default["keystone"]["roles"] = [ "admin", "Member", "KeystoneAdmin", "KeystoneServiceAdmin" ] # node_attribute

#TODO(shep): this should probably be derived from keystone.users hash keys
default["keystone"]["tenants"] = [ "admin", "service"]                      # node_attribute

default["keystone"]["admin_user"] = "admin"                                 # node_attribute

default["keystone"]["users"] = {                                            # node_attribute
    default["keystone"]["admin_user"]  => {
        "password" => "secrete",
        "default_tenant" => "admin",
        "roles" => {
            "admin" => [ "admin" ],
            "KeystoneAdmin" => [ "admin" ],
            "KeystoneServiceAdmin" => [ "admin" ]
        }
    },
    "monitoring" => {
        "password" => "",
        "default_tenant" => "service",
        "roles" => {
            "Member" => [ "admin" ]
        }
    }
}


# platform defaults
case platform
when "fedora", "redhat", "centos"                                 # :pragma-foodcritic: ~FC024 - won't fix this
  default["keystone"]["platform"] = {                                       # node_attribute
    "mysql_python_packages" => [ "MySQL-python" ],
    "keystone_packages" => [ "openstack-keystone" ],
    "keystone_service" => "openstack-keystone",
    "keystone_process_name" => "keystone-all",
    "package_options" => ""
  }
when "ubuntu"
  default["keystone"]["platform"] = {                                       # node_attribute
    "mysql_python_packages" => [ "python-mysqldb" ],
    "keystone_ldap_packages" => [ "python-ldap" ],
    "keystone_packages" => [ "keystone", "python-keystone", "python-keystoneclient" ],
    "keystone_service" => "keystone",
    "keystone_process_name" => "keystone-all",
    "package_options" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
