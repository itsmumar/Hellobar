require "./config/initializers/settings"

GuaranteedQueue.config(
  :access_key_id => Hellobar::Settings[:aws_access_key_id],
  :secret_access_key => Hellobar::Settings[:aws_secret_access_key],
  :queue_env => Hellobar::Settings[:env_name],
  :stub_requests => Rails.env.test? || Rails.env.development? || !!Hellobar::Settings[:process_synchronously]
)
