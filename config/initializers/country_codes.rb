def get_country_options
  countries = YAML.load_file("#{Rails.root.to_s}/config/locales/country_codes.en.yml")["en"]["country_codes"]

  options = []
  countries.each do |country|
    options << [country["name"], country["code"]]
  end

  options
end