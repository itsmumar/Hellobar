require './config/initializers/settings'

# Paperclip configuration (S3)
if !Rails.env.test? && Hellobar::Settings[:s3_bucket] && Hellobar::Settings[:aws_access_key_id] && Hellobar::Settings[:aws_secret_access_key]
  config.paperclip_defaults = {
    storage: :s3,
    s3_protocol: :https,
    s3_credentials: {
      bucket: Hellobar::Settings[:s3_bucket],
      access_key_id: Hellobar::Settings[:aws_access_key_id],
      secret_access_key: Hellobar::Settings[:aws_secret_access_key]
    }
  }
end
