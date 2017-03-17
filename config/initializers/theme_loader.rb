Rails.application.config.to_prepare do
  THEME_DIRECTORY      = 'lib/themes'.freeze
  TEMPLATE_DIRECTORY   = "#{ THEME_DIRECTORY }/templates".freeze
  METADATA_FILENAME    = 'metadata.json'.freeze

  themes = []

  # Collect data for `generic` themes
  themes += collect_data(THEME_DIRECTORY)
  # Collect data for `template` themes
  themes += collect_data(TEMPLATE_DIRECTORY)

  Theme.data = themes
end

def collect_data(directory)
  collected_data = []

  Dir.entries(directory).each do |entry|
    next unless File.directory?(File.join(directory, entry)) &&
                !(entry == '.' || entry == '..')

    metadata_file = File.join(directory, entry, METADATA_FILENAME)
    next unless File.exist?(metadata_file)

    data = JSON.parse(File.read(metadata_file))
    data[:directory] = File.join(directory, entry)

    collected_data << data
  end

  collected_data
end
