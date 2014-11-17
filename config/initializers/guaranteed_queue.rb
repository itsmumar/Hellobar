require "./config/initializers/settings"

GuaranteedQueue.config(
  :access_key_id => Hellobar::Settings[:aws_access_key_id],
  :secret_access_key => Hellobar::Settings[:aws_secret_access_key],
  :queue_name => Hellobar::Settings[:main_queue],
  :poll_interval_seconds => ENV['GUARANTEED_QUEUE_INTERVAL'] || 5,
  :stub_requests => Rails.env.development? || Rails.env.test?
)
