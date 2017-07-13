unless Rails.env.test?
  Pony.options = {
    from: 'Hello Bar Support <support@hellobar.com>',
    via: :smtp,
    via_options: {
      address: 'smtp.sendgrid.net',
      port: 587,
      enable_starttls_auto: true,
      user_name: Settings.sendgrid_user_name,
      password: Settings.sendgrid_password,
      authentication: :plain,
      domain: Settings.host
    }
  }
end
