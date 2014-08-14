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
    aws_access_key_id
    aws_secret_access_key
    s3_bucket
    tracking_host
    env_name
    process_synchronously
    store_site_scripts_locally
    aweber_app_id
    aweber_consumer_secret
    aweber_consumer_key
    createsend_client_id
    createsend_secret
    constantcontact_app_key
    constantcontact_app_secret
    mailchimp_client_id
    mailchimp_secret
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

  config[:identity_providers] = {
    :aweber => {
      :key => :aweber,
      :type => :email,
      :name => 'AWeber',
      :app_id => config[:aweber_app_id],
      :consumer_secret => config[:aweber_consumer_secret],
      :consumer_key => config[:aweber_consumer_key]
    },
    :createsend => {
      :key => :createsend,
      :type => :email,
      :name => 'Campaign Monitor',
      :client_id => config[:createsend_client_id],
      :secret => config[:createsend_secret]
    },
    :constantcontact => {
      :key => :constantcontact,
      :type => :email,
      :name => 'Constant Contact',
      :app_key => config[:constantcontact_app_key],
      :app_secret => config[:constantcontact_app_secret],
      :supports_double_optin => true
    },
    :mailchimp => {
      :key => :mailchimp,
      :type => :email,
      :name => 'MailChimp',
      :client_id => config[:mailchimp_client_id],
      :secret => config[:mailchimp_secret],
      :supports_double_optin => true
    },
    :get_response => {
      :key => :get_response,
      :type => :email,
      :name => "GetResponse",
      :requires_embed_code => true
    },
    :icontact => {
      :key => :icontact,
      :type => :email,
      :name => "iContact",
      :requires_embed_code => true
    },
    :mad_mimi => {
      :key => :mad_mimi,
      :type => :email,
      :name => "Mad Mimi",
      :requires_embed_code => true
    },
    :my_emma => {
      :key => :my_emma,
      :type => :email,
      :name => "MyEmma",
      :requires_embed_code => true
    },
    :vertical_response => {
      :key => :vertical_response,
      :type => :email,
      :name => "VerticalResponse",
      :requires_embed_code => true
    }
  }

  Hellobar::Settings = config
end
