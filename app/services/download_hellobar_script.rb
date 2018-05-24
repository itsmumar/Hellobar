class DownloadHellobarScript
  class ScriptNotFound < StandardError
    def initialize(url)
      super "hellobar script version #{ url.inspect } couldn't be found"
    end
  end

  cattr_accessor :logger do
    Logger.new(STDOUT).tap do |logger|
      logger.formatter = proc { |*_, msg| "#{ msg }\n" }
    end
  end

  def initialize(force: false)
    @force = force
  end

  def call
    download if missing? || force
  end

  private

  attr_reader :force

  def missing?
    Rails.env.test? || !local_path.exist?
  end

  def download
    logger&.info "Downloading #{ filename }..."

    response = HTTParty.get(url)
    raise ScriptNotFound, url unless response.success?

    store_locally response.to_s
  end

  def store_locally(content)
    File.open(local_path, 'wb') { |f| f.puts(content) }
  end

  def local_path
    Rails.root.join('public', 'generated_scripts', filename)
  end

  def url
    "https://#{ Settings.script_cdn_url }/#{ filename }"
  end

  def filename
    HellobarModules.filename
  end
end
