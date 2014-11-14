# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

# role :app, %w{www.hellobar.com}
# role :web, %w{www.hellobar.com}
# role :db,  %w{www.hellobar.com}


# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

server '184.72.141.214', user: 'hellobar', roles: %w{web db cron}
server '23.21.249.113', user: 'hellobar', roles: %w{web} # web2
server '54.235.76.197', user: 'hellobar', roles: %w{web} # web3
server '54.90.172.206', user: 'hellobar', roles: %w{web} # web4
server '54.211.192.176', user: 'hellobar', roles: %w{web} # web

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------

set :ssh_options, {
  forward_agent: true
}

#
# And/or per server (overrides global)
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
