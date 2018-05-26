Rails.application.config.to_prepare do
  Theme.data = collect_data('lib/themes')
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
