unless defined?(Hellobar::Settings)
  settings_file = File.join(Rails.root, "config/settings.yml")
  yaml = File.exists?(settings_file) ? YAML.load_file(settings_file) : {}
  config = {}

  keys = %w(
    twilio_user
    twilio_password
    host
    recaptcha_public_key
    recaptcha_private_key
    sendgrid_password
    grand_central_api_key
    grand_central_api_secret
  )

  keys.each do |key|
    config[key.to_sym] = yaml[key] || ENV[key.upcase]
  end

  dynamo_tables = %w(
    email
    bar_current
    bar_prev
    bar_over_time
  )

  config[:dynamo_tables] = {}

  dynamo_tables.each do |table|
    config[:dynamo_tables][table.to_sym] = yaml["dynamo_tables"].try(:[], table) || "test_#{table}"
  end

  Hellobar::Settings = config
end
