if %x[hostname].strip == 'edge.hellobar.com'
  Site.in_bar_ads_config = {
    test_fraction: 1.0,
    show_to_fraction: 0.9,
    start_date: '2000-01-01'
  }
end
