# Whether or not to hook into the default deployment recipe.
set :shoryuken_default_hooks, true

set :shoryuken_pid, -> { File.join(shared_path, 'tmp', 'pids', 'shoryuken.pid') }
set :shoryuken_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
set :shoryuken_log, -> { File.join(shared_path, 'log', 'shoryuken.log') }
set :shoryuken_config, -> { File.join(release_path, 'config', 'shoryuken.yml') }
set :shoryuken_options, -> { ['--rails'] }
set :shoryuken_role, :worker
