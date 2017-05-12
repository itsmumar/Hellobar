ENV['AWS_REGION'] = Settings.aws_region
Aws.config[:credentials] = Aws::Credentials.new(Settings.aws_access_key_id, Settings.aws_secret_access_key)
