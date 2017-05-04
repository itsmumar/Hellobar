if Rails.env.production? || Rails.env.staging? || Rails.env.edge?
  Paperclip::Attachment.default_options[:storage] = :s3
  Paperclip::Attachment.default_options[:s3_protocol] = :https
  Paperclip::Attachment.default_options[:s3_credentials] = {
    bucket: Settings.s3_bucket,
    access_key_id: Settings.aws_access_key_id,
    secret_access_key: Settings.aws_secret_access_key
  }
elsif Rails.env.development?
  Paperclip::Attachment.default_options[:path] = ':rails_root/public/:class/:id_partition/:style.:extension'
  Paperclip::Attachment.default_options[:url] = '/:class/:id_partition/:style.:extension'
else # Test
  Paperclip::Attachment.default_options[:path] = ':rails_root/tmp/:class/:id_partition/:style.:extension'
end
