Rails.application.config.to_prepare do
  FONT_CONFIG = Rails.root.join('config', 'fonts.yml')
  Font.data = YAML.load_file(FONT_CONFIG)
end
