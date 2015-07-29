if %x[hostname].strip == 'staging.hellobar.com'
  Site.in_bar_ads_config = {
    show_to_fraction: 1.0,
    start_date: '2000-01-01'
  }
end
