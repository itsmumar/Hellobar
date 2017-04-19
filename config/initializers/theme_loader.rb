Rails.application.config.to_prepare do
  theme_directory = 'lib/themes'
  template_directory = "#{ theme_directory }/templates"
  themes = []

  # Collect data for `generic` themes
  themes += collect_data(theme_directory)
  # Collect data for `template` themes
  themes += collect_data(template_directory)

  Theme.data = themes
end

def collect_data(directory)
  metadata_filename = 'metadata.json'
  collected_data = []

  Dir.entries(directory).each do |entry|
    next unless File.directory?(File.join(directory, entry)) &&
                !(entry == '.' || entry == '..')

    metadata_file = File.join(directory, entry, metadata_filename)
    next unless File.exist?(metadata_file)

    data = JSON.parse(File.read(metadata_file))
    data[:directory] = File.join(directory, entry)

    collected_data << data
  end

  collected_data
end
