require "./config/initializers/settings"

GuaranteedQueue.config(
  :access_key_id => Hellobar::Settings[:aws_access_key_id],
  :secret_access_key => Hellobar::Settings[:aws_secret_access_key],
  :queue_name => Hellobar::Settings[:main_queue],
  :poll_interval_seconds => (Hellobar::Settings[:env_name] == "edge") ? 6 : 2
)
