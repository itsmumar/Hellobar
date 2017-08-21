module SiteGeneratorHelper
  INTEGRATION_SITE_DIRECTORY = 'integration'.freeze

  def setup_site_generator
    dir = site_generator_directory
    Dir.mkdir(dir) unless File.directory?(dir)
  end

  def generate_file_and_return_path(site_id)
    generator = TestSiteGenerator.new(site_id, directory: site_generator_directory, compress: true)

    generator.generate_file

    generator.full_path
  end

  def site_path_to_url(path)
    "/#{ INTEGRATION_SITE_DIRECTORY }/#{ path.basename }"
  end

  private

  def site_generator_directory
    Rails.root.join('public', INTEGRATION_SITE_DIRECTORY)
  end
end
