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

# Auth type = sql, ldap (use ad for active directory), pam
default["keystone"]["auth_type"] == "sql"				    # node_attribute

# ldap - base configuration
default["keystone"]["ldap"]["url"] = nil
default["keystone"]["ldap"]["user"] = nil
default["keystone"]["ldap"]["password"] = nil
default["keystone"]["ldap"]["suffix"] = nil
default["keystone"]["ldap"]["use_dumb_member"] = nil
default["keystone"]["ldap"]["dumb_member"] = nil
default["keystone"]["ldap"]["allow_subtree_delete"] = nil
default["keystone"]["ldap"]["query_scope"] = nil
default["keystone"]["ldap"]["page_size"] = nil
default["keystone"]["ldap"]["alias_dereferencing"] = nil

# ldap - User tree setup, dependent on ldap schema
default["keystone"]["ldap"]["user_tree_dn"] = nil
default["keystone"]["ldap"]["user_filter"] = nil
default["keystone"]["ldap"]["user_objectclass"] = nil
default["keystone"]["ldap"]["user_id_attribute"] = nil
default["keystone"]["ldap"]["user_name_attribute"] = nil
default["keystone"]["ldap"]["user_mail_attribute"] = nil
default["keystone"]["ldap"]["user_pass_attribute"] = nil
default["keystone"]["ldap"]["user_enabled_attribute"] = nil
default["keystone"]["ldap"]["user_domain_id_attribute"] = nil
default["keystone"]["ldap"]["user_enabled_mask"] = nil
default["keystone"]["ldap"]["user_enabled_default"] = nil
default["keystone"]["ldap"]["user_attribute_ignore"] = nil
default["keystone"]["ldap"]["user_allow_create"] = nil
default["keystone"]["ldap"]["user_allow_update"] = nil
default["keystone"]["ldap"]["user_allow_delete"] = nil
default["keystone"]["ldap"]["user_enabled_emulation"] = nil
default["keystone"]["ldap"]["user_enabled_emulation_dn"] = nil

# ldap - Tenant tree setup, dependent on ldap schema. Can also use keystone db to manage tenants
default["keystone"]["ldap"]["tenant_tree_dn"] = nil
default["keystone"]["ldap"]["tenant_filter"] = nil
default["keystone"]["ldap"]["tenant_objectclass"] = nil
default["keystone"]["ldap"]["tenant_id_attribute"] = nil
default["keystone"]["ldap"]["tenant_member_attribute"] = nil
default["keystone"]["ldap"]["tenant_name_attribute"] = nil
default["keystone"]["ldap"]["tenant_desc_attribute"] = nil
default["keystone"]["ldap"]["tenant_enabled_attribute"] = nil
default["keystone"]["ldap"]["user_domain_id_attribute"] = nil
default["keystone"]["ldap"]["tenant_attribute_ignore"] = nil
default["keystone"]["ldap"]["tenant_allow_create"] = nil
default["keystone"]["ldap"]["tenant_allow_update"] = nil
default["keystone"]["ldap"]["tenant_allow_delete"] = nil
default["keystone"]["ldap"]["tenant_enabled_emulation"] = nil
default["keystone"]["ldap"]["tenant_enabled_emulation_dn"] = nil

# ldap - Role tree setup, dependent on ldap schema. Can also use keystone db to manage roles
default["keystone"]["ldap"]["role_tree_dn"] = nil
default["keystone"]["ldap"]["role_filter"] = nil
default["keystone"]["ldap"]["role_objectclass"] = nil
default["keystone"]["ldap"]["role_id_attribute"] = nil
default["keystone"]["ldap"]["role_name_attribute"] = nil
default["keystone"]["ldap"]["role_member_attribute"] = nil
default["keystone"]["ldap"]["role_attribute_ignore"] = nil
default["keystone"]["ldap"]["role_allow_create"] = nil
default["keystone"]["ldap"]["role_allow_update"] = nil
default["keystone"]["ldap"]["role_allow_delete"] = nil

# ldap - Group setup (grizzly and beyond)
default["keystone"]["ldap"]["group_tree_dn"] = nil
default["keystone"]["ldap"]["group_filter"] = nil
default["keystone"]["ldap"]["group_objectclass"] = nil
default["keystone"]["ldap"]["group_id_attribute"] = nil
default["keystone"]["ldap"]["group_name_attribute"] = nil
default["keystone"]["ldap"]["group_member_attribute"] = nil
default["keystone"]["ldap"]["group_desc_attribute"] = nil
default["keystone"]["ldap"]["group_domain_id_attribute"] = nil
default["keystone"]["ldap"]["group_attribute_ignore"] = nil
default["keystone"]["ldap"]["group_allow_create"] = nil
default["keystone"]["ldap"]["group_allow_update"] = nil
default["keystone"]["ldap"]["group_allow_delete"] = nil

# ldap - domain setup (grizzly and beyond)
default["keystone"]["ldap"]["domain_tree_dn"] = nil
default["keystone"]["ldap"]["domain_filter"] = nil
default["keystone"]["ldap"]["domain_objectclass"] = nil
default["keystone"]["ldap"]["domain_id_attribute"] = nil
default["keystone"]["ldap"]["domain_name_attribute"] = nil
default["keystone"]["ldap"]["domain_member_attribute"] = nil
default["keystone"]["ldap"]["domain_desc_attribute"] = nil
default["keystone"]["ldap"]["domain_enabled_attribute"] = nil
default["keystone"]["ldap"]["domain_attribute_ignore"] = nil
default["keystone"]["ldap"]["domain_allow_create"] = nil
default["keystone"]["ldap"]["domain_allow_delete"] = nil
default["keystone"]["ldap"]["domain_allow_update"] = nil
default["keystone"]["ldap"]["domain_enabled_emulation"] = nil
default["keystone"]["ldap"]["domain_enabled_emulation_dn"] = nil

# ldap - SSL setup
default["keystone"]["ldap"]["tls_cacertfile"] = nil
default["keystone"]["ldap"]["tls_cacertdir"] = nil
default["keystone"]["ldap"]["use_tls"] = nil
default["keystone"]["ldap"]["tls_req_cert"] = nil

# PAM Support
default["keystone"]["pam"]["url"] = nil
default["keystone"]["pam"]["userid"] = nil
default["keystone"]["pam"]["password"] = nil

# setting to false will use a token_format of UUID
default["keystone"]["pki"]["enabled"] = true

# new endpoint location stuff
default["keystone"]["services"]["admin-api"]["scheme"] = "http"             # node_attribute
default["keystone"]["services"]["admin-api"]["network"] = "nova"            # node_attribute
default["keystone"]["services"]["admin-api"]["port"] = "35357"              # node_attribute
default["keystone"]["services"]["admin-api"]["path"] = "/v2.0"              # node_attribute

default["keystone"]["services"]["service-api"]["scheme"] = "http"           # node_attribute
default["keystone"]["services"]["service-api"]["network"] = "public"        # node_attribute
default["keystone"]["services"]["service-api"]["port"] = "5000"             # node_attribute
default["keystone"]["services"]["service-api"]["path"] = "/v2.0"            # node_attribute

default["keystone"]["services"]["internal-api"]["scheme"] = "http"           # node_attribute
default["keystone"]["services"]["internal-api"]["network"] = "management"        # node_attribute
default["keystone"]["services"]["internal-api"]["port"] = "5000"             # node_attribute
default["keystone"]["services"]["internal-api"]["path"] = "/v2.0"            # node_attribute

# Logging stuff
default["keystone"]["syslog"]["use"] = true                                 # node_attribute
default["keystone"]["syslog"]["facility"] = "LOG_LOCAL3"                    # node_attribute
default["keystone"]["syslog"]["config_facility"] = "local3"                 # node_attribute

# default["keystone"]["roles"] = [ "admin", "Member", "KeystoneAdmin", "KeystoneServiceAdmin", "sysadmin", "netadmin" ]
default["keystone"]["roles"] = [ "admin", "Member", "KeystoneAdmin", "KeystoneServiceAdmin" ] # node_attribute

#TODO(shep): this should probably be derived from keystone.users hash keys
default["keystone"]["tenants"] = [ "admin", "service"]                      # node_attribute

# LOGGING LEVEL
# in order of verbosity (most to least)
# DEBUG, INFO, WARNING, ERROR, CRITICAL
default["keystone"]["config"]["log_verbosity"] = "INFO"                                     # node attributes


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
    "keystone_ldap_packages" => [ "python-ldap" ],
    "keystone_packages" => [ "openstack-keystone", "python-iso8601" ],
    "keystone_service" => "openstack-keystone",
    "keystone_process_name" => "keystone-all",
    "package_options" => ""
  }
when "ubuntu"
  default["keystone"]["platform"] = {                                       # node_attribute
    "mysql_python_packages" => [ "python-mysqldb" ],
    "keystone_ldap_packages" => [ "python-ldap" ],
    "keystone_packages" => [ "python-keystone", "keystone", "python-keystoneclient" ],
    "keystone_service" => "keystone",
    "keystone_process_name" => "keystone-all",
    "package_options" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
