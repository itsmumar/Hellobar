require "./config/initializers/settings"

require "./lib/service_provider"
Dir["./lib/service_providers/**/*.rb"].each { |f| require f }
