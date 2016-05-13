Rails.application.config.to_prepare do
  THEME_DIRECTORY   = 'lib/themes'
  METADATA_FILENAME = 'metadata.json'

  themes = []

  Dir.entries(THEME_DIRECTORY).each do |entry|
    next unless File.directory?(File.join(THEME_DIRECTORY, entry)) &&
                !(entry == '.' || entry == '..')

    metadata_file = File.join(THEME_DIRECTORY, entry, METADATA_FILENAME)
    next unless File.exist?(metadata_file)

    data = JSON.parse(File.read(metadata_file))
    data[:directory] = File.join(THEME_DIRECTORY, entry)

    themes << data
  end

  Theme.data = themes
end
