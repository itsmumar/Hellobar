IntercomRails.config do |config|
  # == Intercom app_id
  #
  config.app_id = ENV['INTERCOM_APP_ID'] || Settings.intercom_id

  # == Intercom session_duration
  #
  # config.session_duration = 300000
  # == Intercom secret key
  # This is required to enable secure mode, you can find it on your Setup
  # guide in the "Secure Mode" step.
  # https://docs.intercom.com/configure-intercom-for-your-product-or-site/staying-secure/enable-identity-verification-on-your-web-product
  #
  config.api_secret = Settings.intercom_secret

  # == Enabled Environments
  # Which environments is auto inclusion of the Javascript enabled for
  #
  # config.enabled_environments = %w[production staging edge]
  config.enabled_environments = %w[]

  # == Current user method/variable
  # The method/variable that contains the logged in user in your controllers.
  # If it is `current_user` or `@user`, then you can ignore this
  #
  # config.user.current = Proc.new { current_user }
  # config.user.current = [Proc.new { current_user }]

  # == Include for logged out Users
  # If set to true, include the Intercom messenger on all pages, regardless of whether
  # The user model class (set below) is present. Only available for Apps on the Acquire plan.
  # config.include_for_logged_out_users = true

  # == User model class
  # The class which defines your user model
  #
  # config.user.model = Proc.new { User }

  # == Lead/custom attributes for non-signed up users
  # Pass additional attributes to for potential leads or
  # non-signed up users as an an array.
  # Any attribute contained in config.user.lead_attributes can be used
  # as custom attribute in the application.
  # config.user.lead_attributes = %w(first_name last_name)

  # == Exclude users
  # A Proc that given a user returns true if the user should be excluded
  # from imports and Javascript inclusion, false otherwise.
  #
  config.user.exclude_if = proc { |user| user.is_impersonated }

  # == User Custom Data
  # A hash of additional data you wish to send about your users.
  # You can provide either a method name which will be sent to the current
  # user object, or a Proc which will be passed the current user.
  #
  config.user.custom_data = {
    first_name: proc { |user| user.first_name },
    last_name: proc { |user| user.last_name },
    primary_domain: proc { |user| NormalizeURI[user.sites.first&.url]&.domain },
    additional_domains: proc { |user| user.sites.map { |site| NormalizeURI[site.url]&.domain }.compact.join(', ') },
    contact_lists: proc { |user| user.contact_lists.count },
    total_views: proc { |user| user.sites.map { |site| site.statistics.views }.sum },
    total_conversions: proc { |user| user.sites.map { |site| site.statistics.conversions }.sum },
    total_subscribers: proc { |user| user.sites.to_a.sum { |s| FetchSiteContactListTotals.new(s).call.values.sum || 0 } },
    managed_sites: proc { |user| user.site_ids },
    affiliate_identifier: proc { |user| user.affiliate_identifier }
  }

  # == Current company method/variable
  # The method/variable that contains the current company for the current user,
  # in your controllers. 'Companies' are generic groupings of users, so this
  # could be a company, app or group.
  #
  # config.company.current = Proc.new { current_company }
  #
  # Or if you are using devise you can just use the following config
  #
  # config.company.current = Proc.new { current_user.company }

  # == Exclude company
  # A Proc that given a company returns true if the company should be excluded
  # from imports and Javascript inclusion, false otherwise.
  #
  # config.company.exclude_if = Proc.new { |app| app.subdomain == 'demo' }

  # == Company Custom Data
  # A hash of additional data you wish to send about a company.
  # This works the same as User custom data above.
  #
  # config.company.custom_data = {
  #   :number_of_messages => Proc.new { |app| app.messages.count },
  #   :is_interesting => :is_interesting?
  # }

  # == Company Plan name
  # This is the name of the plan a company is currently paying (or not paying) for.
  # e.g. Messaging, Free, Pro, etc.
  #
  # config.company.plan = Proc.new { |current_company| current_company.plan.name }

  # == Company Monthly Spend
  # This is the amount the company spends each month on your app. If your company
  # has a plan, it will set the 'total value' of that plan appropriately.
  #
  # config.company.monthly_spend = Proc.new { |current_company| current_company.plan.price }
  # config.company.monthly_spend = Proc.new { |current_company| (current_company.plan.price - current_company.subscription.discount) }

  # == Custom Style
  # By default, Intercom will add a button that opens the messenger to
  # the page. If you'd like to use your own link to open the messenger,
  # uncomment this line and clicks on any element with id 'Intercom' will
  # open the messenger.
  #
  # config.inbox.style = :custom
  #
  # If you'd like to use your own link activator CSS selector
  # uncomment this line and clicks on any element that matches the query will
  # open the messenger
  # config.inbox.custom_activator = '.intercom'
  #
  # If you'd like to hide default launcher button uncomment this line
  # config.hide_default_launcher = true

  # Display Messenger for logged out users
  config.include_for_logged_out_users = true
end
