if Rails.env.test?
  Site.in_bar_ads_config = {
    show_to_fraction: 0.0
  }
elsif Rails.env.development?
  Site.in_bar_ads_config = {
    show_to_fraction: 0.5
  }
elsif Rails.env.production?
  Site.in_bar_ads_config = {
    show_to_fraction: 0.1
  }
end
