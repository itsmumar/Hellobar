require "./config/initializers/settings"

require "./lib/service_provider"
require "./lib/service_providers/email"
require "./lib/service_providers/embed_code_provider"
Dir["./lib/service_providers/**/*.rb"].each { |f| require f }
