require './config/initializers/settings'

if Rails.env.production?
  Pony.options = {
    from: 'Hello Bar Support <support@hellobar.com>',
    via: :smtp,
    via_options: {
      address: 'smtp.sendgrid.net',
      port: 587,
      enable_starttls_auto: true,
      user_name: 'support@crazyegg.com',
      password: Hellobar::Settings[:sendgrid_password],
      authentication: :plain,
      domain: 'crazyegg.com'
    }
  }
end
