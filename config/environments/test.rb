Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.serve_static_assets  = true
  config.static_cache_control = 'public, max-age=3600'
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.delivery_method = :test
  config.active_support.deprecation = :stderr

  # putting test files into a sensible location
  # Paperclip::Attachment.default_options[:path] = "#{Rails.root}/spec/test_files/:class/:id_partition/:style.:extension"

  # Configure Rails.cache store for test environment
  # With this cache store, all fetch and read operations will result in a miss.
  config.cache_store = :null_store

  # Rails 4.1 is not thread-safe; disable concurrency
  # See https://github.com/teamcapybara/capybara#setup
  config.allow_concurrency = false
end
