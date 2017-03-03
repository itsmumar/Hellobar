class WordpressPlugin
  include RenderAnywhere
  include SitesHelper

  attr_accessor :site, :file

  def initialize(site)
    @site = site
    @file = Tempfile.new("hellobar_wp_plugin-#{Time.current.to_i}.zip")
  end

  def content
    set_render_anywhere_helpers(SitesHelper)
    render template: 'wordpress_plugin/show', layout: false, locals: { site: site }
  end

  def cleanup
    file.close
    file.unlink
  end

  def to_zip
    Zip::ZipOutputStream.open(file.path) do |zip|
      zip.put_next_entry('hellobar_wp_plugin.php')
      zip.print(content)
    end

    file.rewind
    file.read
  end
end
