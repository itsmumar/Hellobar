require './config/initializers/settings'

# Paperclip configuration (S3)
if !Rails.env.test? && Hellobar::Settings[:s3_bucket] && Hellobar::Settings[:aws_access_key_id] && Hellobar::Settings[:aws_secret_access_key]
  Paperclip::Attachment.default_options[:storage] = :s3
  Paperclip::Attachment.default_options[:s3_protocol] = :https
  Paperclip::Attachment.default_options[:s3_credentials] = {
    bucket: Hellobar::Settings[:s3_bucket],
    access_key_id: Hellobar::Settings[:aws_access_key_id],
    secret_access_key: Hellobar::Settings[:aws_secret_access_key]
  }
else
  # Tests
  Paperclip::Attachment.default_options[:path] = ':rails_root/tmp/uploads/:class/:id_partition/:style.:extension'
end
