unless defined?(Hellobar::Settings)
  settings_file = File.join(Rails.root, "config/settings.yml")
  yaml = File.exists?(settings_file) ? YAML.load_file(settings_file) : {}
  config = {}

  keys = %w(
    analytics_log_file
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
    deliver_emails
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
    recaptcha_private_key
    recaptcha_public_key
    s3_bucket
    script_cdn_url
    sendgrid_password
    sentry_dsn
    store_site_scripts_locally
    syncable
    tracking_host
    twilio_password
    twilio_user
    support_location
    google_auth_id
    google_auth_secret
    drip_client_id
    drip_secret
    get_response_api_url
    vr_client_id
    vr_secret
    infusionsoft_key
    infusionsoft_secret
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
    :drip => {
      :type => :email,
      :name => 'Drip',
      :client_id => config[:drip_client_id],
      :secret => config[:drip_secret],
      :supports_double_optin => true,
      :oauth => true
    },
    :get_response => {
      :type => :email,
      :name => "GetResponse",
      :requires_embed_code => true,
      :hidden => true
    },
    :get_response_api => {
      :type => :email,
      :name => "GetResponse",
      :service_provider_class => "GetResponseApi",
      :requires_api_key => true
    },
    :icontact => {
      :type => :email,
      :service_provider_class => "IContact",
      :name => "iContact",
      :requires_embed_code => true
    },
    :mad_mimi_form => {
      :type => :email,
      :service_provider_class => "MadMimiForm",
      :name => "Mad Mimi",
      :requires_embed_code => true,
      :hidden => true
    },
    :mad_mimi_api => {
      :type => :email,
      :service_provider_class => "MadMimiApi",
      :name => "Mad Mimi",
      :requires_api_key => true,
      :requires_username => true
    },
    :my_emma => {
      :type => :email,
      :name => "MyEmma",
      :requires_embed_code => true
    },
    #silly name to support oauth strategy gem
    :verticalresponse => {
      :type => :email,
      :name => 'Vertical Response',
      :client_id => config[:vr_client_id],
      :secret => config[:vr_secret],
      :service_provider_class => "VerticalResponseApi",
      :supports_double_optin => false,
      :oauth => true
    },
    :vertical_response => {
      :type => :email,
      :name => "VerticalResponse",
      :requires_embed_code => true,
      :hidden => true
    },
    :infusionsoft => {
      :type => :email,
      :name => "Infusionsoft",
      :client_id => config[:infusionsoft_key],
      :secret => config[:infusionsoft_secret],
      :supports_double_optin => true,
      :oauth => true
    }
  }
  config[:analytics_log_file] ||= File.join(Rails.root, "log", "analytics.log")

  config[:permissions] = {
    "owner" => [:billing, :edit_owner]
  }

  Hellobar::Settings = config
end
