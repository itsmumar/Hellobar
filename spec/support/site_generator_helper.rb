module SiteGeneratorHelper
  INTEGRATION_SITE_DIRECTORY = 'integration'

  def setup_site_generator
    dir = site_generator_directory
    Dir.mkdir(dir) unless File.directory?(dir)
  end

  def generate_file_and_return_path(site_id)
    allow_any_instance_of(Site)
      .to receive(:lifetime_totals).and_return('1' => [[1, 0]])
    generator = SiteGenerator.new(site_id, directory: site_generator_directory)

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
