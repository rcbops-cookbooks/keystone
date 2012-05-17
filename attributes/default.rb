# Adding these as blank
# this needs to be here for the initial deep-merge to work
default["credentials"]["EC2"]["admin"]["access"] = ""
default["credentials"]["EC2"]["admin"]["secret"] = ""

default["keystone"]["db"] = "keystone"
default["keystone"]["db_user"] = "keystone"
default["keystone"]["db_passwd"] = "keystone"
default["keystone"]["api_ipaddress"] = node["ipaddress"]
default["keystone"]["verbose"] = "False"
default["keystone"]["debug"] = "False"
default["keystone"]["service_port"] = "5000"
default["keystone"]["admin_port"] = "35357"
default["keystone"]["admin_token"] = "999888777666"

# default["keystone"]["roles"] = [ "admin", "Member", "KeystoneAdmin", "KeystoneServiceAdmin", "sysadmin", "netadmin" ]
default["keystone"]["roles"] = [ "admin", "Member", "KeystoneAdmin", "KeystoneServiceAdmin" ]

default["keystone"]["tenants"] = [ "admin", "demo"]

default["keystone"]["admin_user"] = "admin"

default["keystone"]["users"] = {
    default["keystone"]["admin_user"]  => {
        "password" => "dsecrete",
        "default_tenant" => "admin",
        "roles" => {
            "admin" => [ "admin", "demo" ],
            "KeystoneAdmin" => [ "admin" ],
            "KeystoneServiceAdmin" => [ "admin" ]
        }
    },
    "demo" => {
        "password" => "secrete",
        "default_tenant" => "demo",
        "roles" => {
            "Member" => [ "demo" ]
        }
    },
}
