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
default["keystone"]["ldap"]["url"] = ""
default["keystone"]["ldap"]["user"] = ""
default["keystone"]["ldap"]["password"] = ""
default["keystone"]["ldap"]["suffix"] = ""
default["keystone"]["ldap"]["use_dumb_member"] = ""
default["keystone"]["ldap"]["dumb_member"] = ""
default["keystone"]["ldap"]["allow_subtree_delete"] = ""
default["keystone"]["ldap"]["query_scope"] = ""
default["keystone"]["ldap"]["page_size"] = ""
default["keystone"]["ldap"]["alias_dereferencing"] = ""

# ldap - User tree setup, dependent on ldap schema
default["keystone"]["ldap"]["user_tree_dn"] = ""
default["keystone"]["ldap"]["user_filter"] = ""
default["keystone"]["ldap"]["user_objectclass"] = ""
default["keystone"]["ldap"]["user_id_attribute"] = ""
default["keystone"]["ldap"]["user_name_attribute"] = ""
default["keystone"]["ldap"]["user_mail_attribute"] = ""
default["keystone"]["ldap"]["user_pass_attribute"] = ""
default["keystone"]["ldap"]["user_enabled_attribute"] = ""
default["keystone"]["ldap"]["user_domain_id_attribute"] = ""
default["keystone"]["ldap"]["user_enabled_mask"] = ""
default["keystone"]["ldap"]["user_enabled_default"] = ""
default["keystone"]["ldap"]["user_attribute_ignore"] = ""
default["keystone"]["ldap"]["user_allow_create"] = ""
default["keystone"]["ldap"]["user_allow_update"] = ""
default["keystone"]["ldap"]["user_allow_delete"] = ""
default["keystone"]["ldap"]["user_enabled_emulation"] = ""
default["keystone"]["ldap"]["user_enabled_emulation_dn"] = ""

# ldap - Tenant tree setup, dependent on ldap schema. Can also use keystone db to manage tenants
default["keystone"]["ldap"]["tenant_tree_dn"] = ""
default["keystone"]["ldap"]["tenant_filter"] = ""
default["keystone"]["ldap"]["tenant_objectclass"] = ""
default["keystone"]["ldap"]["tenant_id_attribute"] = ""
default["keystone"]["ldap"]["tenant_member_attribute"] = ""
default["keystone"]["ldap"]["tenant_name_attribute"] = ""
default["keystone"]["ldap"]["tenant_desc_attribute"] = ""
default["keystone"]["ldap"]["tenant_enabled_attribute"] = ""
default["keystone"]["ldap"]["user_domain_id_attribute"] = ""
default["keystone"]["ldap"]["tenant_attribute_ignore"] = ""
default["keystone"]["ldap"]["tenant_allow_create"] = ""
default["keystone"]["ldap"]["tenant_allow_update"] = ""
default["keystone"]["ldap"]["tenant_allow_delete"] = ""
default["keystone"]["ldap"]["tenant_enabled_emulation"] = ""
default["keystone"]["ldap"]["tenant_enabled_emulation_dn"] = ""

# ldap - Role tree setup, dependent on ldap schema. Can also use keystone db to manage roles
default["keystone"]["ldap"]["role_tree_dn"] = ""
default["keystone"]["ldap"]["role_filter"] = ""
default["keystone"]["ldap"]["role_objectclass"] = ""
default["keystone"]["ldap"]["role_id_attribute"] = ""
default["keystone"]["ldap"]["role_name_attribute"] = ""
default["keystone"]["ldap"]["role_member_attribute"] = ""
default["keystone"]["ldap"]["role_attribute_ignore"] = ""
default["keystone"]["ldap"]["role_allow_create"] = ""
default["keystone"]["ldap"]["role_allow_update"] = ""
default["keystone"]["ldap"]["role_allow_delete"] = ""

# ldap - Group setup (grizzly and beyond)
default["keystone"]["ldap"]["group_tree_dn"] = ""
default["keystone"]["ldap"]["group_filter"] = ""
default["keystone"]["ldap"]["group_objectclass"] = ""
default["keystone"]["ldap"]["group_id_attribute"] = ""
default["keystone"]["ldap"]["group_name_attribute"] = ""
default["keystone"]["ldap"]["group_member_attribute"] = ""
default["keystone"]["ldap"]["group_desc_attribute"] = ""
default["keystone"]["ldap"]["group_domain_id_attribute"] = ""
default["keystone"]["ldap"]["group_attribute_ignore"] = ""
default["keystone"]["ldap"]["group_allow_create"] = ""
default["keystone"]["ldap"]["group_allow_update"] = ""
default["keystone"]["ldap"]["group_allow_delete"] = ""

# ldap - domain setup (grizzly and beyond)
default["keystone"]["ldap"]["domain_tree_dn"] = ""
default["keystone"]["ldap"]["domain_filter"] = ""
default["keystone"]["ldap"]["domain_objectclass"] = ""
default["keystone"]["ldap"]["domain_id_attribute"] = ""
default["keystone"]["ldap"]["domain_name_attribute"] = ""
default["keystone"]["ldap"]["domain_member_attribute"] = ""
default["keystone"]["ldap"]["domain_desc_attribute"] = ""
default["keystone"]["ldap"]["domain_enabled_attribute"] = ""
default["keystone"]["ldap"]["domain_attribute_ignore"] = ""
default["keystone"]["ldap"]["domain_allow_create"] = ""
default["keystone"]["ldap"]["domain_allow_delete"] = ""
default["keystone"]["ldap"]["domain_allow_update"] = ""
default["keystone"]["ldap"]["domain_enabled_emulation"] = ""
default["keystone"]["ldap"]["domain_enabled_emulation_dn"] = ""

# ldap - SSL setup
default["keystone"]["ldap"]["tls_cacertfile"] = ""
default["keystone"]["ldap"]["tls_cacertdir"] = ""
default["keystone"]["ldap"]["use_tls"] = ""
default["keystone"]["ldap"]["tls_req_cert"] = ""

# PAM Support
default["keystone"]["pam"]["url"] = ""
default["keystone"]["pam"]["userid"] = ""
default["keystone"]["pam"]["password"] = ""

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
