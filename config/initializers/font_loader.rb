Rails.application.config.to_prepare do
  font_config = Rails.root.join('config', 'fonts.yml')
  Font.data = YAML.load_file font_config
end
