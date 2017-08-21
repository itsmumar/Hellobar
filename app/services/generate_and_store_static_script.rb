class GenerateAndStoreStaticScript
  # @param [Site] site
  def initialize(site, options = {})
    @site = site
    @options = options
  end

  def call
    site.update_column(:script_attempted_to_generate_at, Time.current)

    UpdateModulesScript.new.call if Rails.env.development? || Rails.env.test?

    if store_site_scripts_locally?
      store_locally
    else
      store_remotely
    end

    site.update_column(:script_generated_at, Time.current)
  end

  private

  attr_reader :site, :options

  def script_content
    @script_content ||= options[:script_content] || RenderStaticScript.new(site, compress: compress_script?).call
  end

  def store_locally
    File.open(local_path, 'w') { |f| f.puts(script_content) }
  end

  def store_remotely
    UploadToS3.new(site.script_name, script_content).call
    store_wordpress_bars
  end

  def store_wordpress_bars
    wordpress_elements_and_users = site.site_elements.wordpress_bars.to_a.product(site.users.wordpress_users)

    wordpress_elements_and_users.each do |site_element, user|
      name = "#{ user.wordpress_user_id }_#{ site_element.wordpress_bar_id }.js"
      UploadToS3.new(name, script_content).call
    end
  end

  def compress_script?
    !store_site_scripts_locally?
  end

  def local_path
    Rails.root.join('public', 'generated_scripts', options[:path] || site.script_name)
  end

  def store_site_scripts_locally?
    Settings.store_site_scripts_locally
  end
end
