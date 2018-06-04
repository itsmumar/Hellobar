require_relative '../../app/core/hellobar_modules'

namespace :modules do
  desc 'Increase hellobar modules version'
  task :bump do
    version = HellobarModules.bump!
    `git add .hellobar-modules-version && git ci -m "Bump v#{ version } modules"`
  end
end
