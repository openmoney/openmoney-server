require 'deprec/recipes'

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

set :domain, "rubyom.openmoney.info"
role :web, domain
role :app, domain
role :db,  domain, :primary => true
#role :scm, domain

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :application, "rubyom"
set :deploy_to, "/var/www/apps/#{application}"

# XXX we may not need this - it doesn't work on windows
set :user, "rubyom"
#set :repository, "svn+ssh://#{user}@#{domain}#{deploy_to}/repos/trunk"
set :svn_password, "fishfish"
set :svn_username, "zippy"
set :repository, "svn+ssh://zippy@rubyforge.org/var/svn/openmoney/rubyom/trunk"
set :rails_env, "production"

# Automatically symlink these directories from current/public to shared/public.
# set :app_symlinks, %w{photo, document, asset}

# =============================================================================
# SPECIAL OPTIONS
# =============================================================================
# These options allow you to tweak deprec behaviour

# If you do not keep database.yml in source control, set this to false.
# After new code is deployed, deprec will symlink current/config/database.yml 
# to shared/config/database.yml
#
# You can generate shared/config/database.yml with 'cap generate_database_yml'
#
 set :database_yml_in_scm, false

# =============================================================================
# APACHE OPTIONS
# =============================================================================
set :apache_server_name, domain
# set :apache_server_aliases, %w{alias1 alias2}
# set :apache_default_vhost, true # force use of apache_default_vhost_config
# set :apache_default_vhost_conf, "/usr/local/apache2/conf/default.conf"
 set :apache_conf, "/usr/local/apache2/conf/apps/#{application}.conf"
 set :apache_ctl, "/etc/init.d/httpd"
 set :apache_proxy_port, 8000
 set :apache_proxy_servers, 2
 set :apache_proxy_address, "127.0.0.1"
# set :apache_ssl_enabled, false
# set :apache_ssl_ip, "127.0.0.1"
# set :apache_ssl_forward_all, false
# set :apache_ssl_chainfile, false


# =============================================================================
# MONGREL OPTIONS
# =============================================================================
 set :mongrel_servers, apache_proxy_servers
 set :mongrel_port, apache_proxy_port
set :mongrel_address, apache_proxy_address
 set :mongrel_environment, "production"
 set :mongrel_config, "/etc/mongrel_cluster/#{application}.conf"
# set :mongrel_user_prefix,  'mongrel_'
# set :mongrel_user, mongrel_user_prefix + application
# set :mongrel_group_prefix,  'app_'
# set :mongrel_group, mongrel_group_prefix + application

# =============================================================================
# MYSQL OPTIONS
# =============================================================================


# =============================================================================
# SSH OPTIONS
# =============================================================================
# ssh_options[:keys] = %w(/path/to/my/key /path/to/another/key)
# ssh_options[:port] = 25
