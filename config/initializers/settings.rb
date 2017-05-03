unless defined?(Hellobar::Settings)
  settings_file = Rails.root.join('config', 'settings.yml')
  yaml = File.exist?(settings_file) ? YAML.load_file(settings_file) : {}
  config = {}

  keys = %w[
    aweber_app_id
    aweber_consumer_key
    aweber_consumer_secret
    aws_access_key_id
    aws_secret_access_key
    constantcontact_app_key
    constantcontact_app_secret
    createsend_client_id
    createsend_secret
    cybersource_login
    cybersource_password
    data_api_url
    deliver_emails
    drip_client_id
    drip_secret
    fake_data_api
    geolocation_url
    get_response_api_url
    google_auth_id
    google_auth_secret
    grand_central_api_key
    grand_central_api_secret
    host
    low_priority_queue
    mailchimp_client_id
    mailchimp_secret
    main_queue
    maropost_url
    memcached_server
    s3_bucket
    s3_content_upgrades_bucket
    script_cdn_url
    sendgrid_password
    sentry_dsn
    store_site_scripts_locally
    syncable
    test_cloning
    tracking_host
    vr_client_id
    vr_secret
  ]

  keys.each do |key|
    config[key.to_sym] = yaml[key] || ENV[key.upcase]
  end

  config[:data_api_url] ||= 'http://mock-hi.hellobar.com'

  config[:identity_providers] = {
    active_campaign: {
      type: :email,
      name: 'Active Campaign',
      requires_api_key: true,
      requires_app_url: true,
      service_provider_class: 'ActiveCampaign'
    },
    aweber: {
      type: :email,
      name: 'AWeber',
      app_id: config[:aweber_app_id],
      consumer_secret: config[:aweber_consumer_secret],
      consumer_key: config[:aweber_consumer_key],
      oauth: true
    },
    createsend: {
      type: :email,
      service_provider_class: 'CampaignMonitor',
      name: 'Campaign Monitor',
      client_id: config[:createsend_client_id],
      secret: config[:createsend_secret],
      oauth: true
    },
    constantcontact: {
      type: :email,
      service_provider_class: 'ConstantContact',
      name: 'Constant Contact',
      app_key: config[:constantcontact_app_key],
      app_secret: config[:constantcontact_app_secret],
      oauth: true
    },
    convert_kit: {
      type: :email,
      name: 'ConvertKit',
      service_provider_class: 'ConvertKit',
      requires_api_key: true
    },
    drip: {
      type: :email,
      name: 'Drip',
      client_id: config[:drip_client_id],
      secret: config[:drip_secret],
      supports_double_optin: true,
      oauth: true
    },
    get_response_api: {
      type: :email,
      name: 'GetResponse',
      service_provider_class: 'GetResponseApi',
      requires_api_key: true
    },
    icontact: {
      type: :email,
      service_provider_class: 'IContact',
      name: 'iContact',
      requires_embed_code: true
    },
    infusionsoft: {
      type: :email,
      name: 'Infusionsoft',
      requires_api_key: true,
      requires_app_url: true
    },
    mad_mimi_form: {
      type: :email,
      service_provider_class: 'MadMimiForm',
      name: 'MadMimi',
      requires_embed_code: true,
      hidden: true
    },
    mad_mimi_api: {
      type: :email,
      service_provider_class: 'MadMimiApi',
      name: 'MadMimi',
      requires_api_key: true,
      requires_username: true
    },
    mailchimp: {
      type: :email,
      name: 'MailChimp',
      client_id: config[:mailchimp_client_id],
      secret: config[:mailchimp_secret],
      supports_double_optin: true,
      oauth: true
    },
    maropost: {
      type: :email,
      service_provider_class: 'Maropost',
      name: 'Maropost',
      requires_account_id: true,
      requires_api_key: true
    },
    my_emma: {
      type: :email,
      name: 'MyEmma',
      requires_embed_code: true
    },
    # silly name to support oauth strategy gem
    verticalresponse: {
      type: :email,
      name: 'Vertical Response',
      client_id: config[:vr_client_id],
      secret: config[:vr_secret],
      service_provider_class: 'VerticalResponseApi',
      supports_double_optin: false,
      oauth: true
    },
    webhooks: {
      type: :email,
      name: 'Webhooks',
      service_provider_class: 'Webhook',
      requires_webhook_url: true
    },
    vertical_response: {
      type: :email,
      name: 'VerticalResponse',
      requires_embed_code: true,
      hidden: true
    }
  }

  config[:permissions] = {
    'owner' => %i[billing edit_owner]
  }

  Hellobar::Settings = config
end
