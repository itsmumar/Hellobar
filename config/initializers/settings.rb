unless defined?(Hellobar::Settings)
  settings_file = File.join(Rails.root, "config/settings.yml")
  yaml = File.exists?(settings_file) ? YAML.load_file(settings_file) : {}
  config = {}

  keys = %w(
    aweber_app_id
    aweber_consumer_key
    aweber_consumer_secret
    aws_access_key_id
    aws_secret_access_key
    constantcontact_app_key
    constantcontact_app_secret
    createsend_client_id
    createsend_secret
    cybersource_environment
    cybersource_login
    cybersource_password
    data_api_url
    deliver_email_digests
    env_name
    fake_data_api
    grand_central_api_key
    grand_central_api_secret
    host
    loggly_url
    low_priority_queue
    mailchimp_client_id
    mailchimp_secret
    main_queue
    memcached_server
    process_synchronously
    recaptcha_private_key
    recaptcha_public_key
    s3_bucket
    script_cdn_url
    sendgrid_password
    store_site_scripts_locally
    tracking_host
    twilio_password
    twilio_user
  )

  keys.each do |key|
    config[key.to_sym] = yaml[key] || ENV[key.upcase]
  end

  config[:data_api_url] ||= "http://mock-hi.hellobar.com"

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
      :type => :email,
      :name => 'AWeber',
      :app_id => config[:aweber_app_id],
      :consumer_secret => config[:aweber_consumer_secret],
      :consumer_key => config[:aweber_consumer_key],
      :oauth => true
    },
    :createsend => {
      :type => :email,
      :service_provider_class => "CampaignMonitor",
      :name => 'Campaign Monitor',
      :client_id => config[:createsend_client_id],
      :secret => config[:createsend_secret],
      :oauth => true
    },
    :constantcontact => {
      :type => :email,
      :service_provider_class => "ConstantContact",
      :name => 'Constant Contact',
      :app_key => config[:constantcontact_app_key],
      :app_secret => config[:constantcontact_app_secret],
      :supports_double_optin => true,
      :oauth => true
    },
    :mailchimp => {
      :type => :email,
      :name => 'MailChimp',
      :client_id => config[:mailchimp_client_id],
      :secret => config[:mailchimp_secret],
      :supports_double_optin => true,
      :oauth => true
    },
    :get_response => {
      :type => :email,
      :name => "GetResponse",
      :requires_embed_code => true
    },
    :icontact => {
      :type => :email,
      :service_provider_class => "IContact",
      :name => "iContact",
      :requires_embed_code => true
    },
    :mad_mimi => {
      :type => :email,
      :service_provider_class => "MadMimi",
      :name => "Mad Mimi",
      :requires_embed_code => true
    },
    :my_emma => {
      :type => :email,
      :name => "MyEmma",
      :requires_embed_code => true
    },
    :vertical_response => {
      :type => :email,
      :name => "VerticalResponse",
      :requires_embed_code => true
    }
  }

  Hellobar::Settings = config
end
