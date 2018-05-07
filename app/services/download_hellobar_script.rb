class DownloadHellobarScript
  class ScriptNotFound < StandardError
    def initialize(version)
      super "hellobar script version #{ version.inspect } couldn't be found"
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
    download if stale? || force
  end

  private

  attr_reader :force

  def stale?
    !local_path.exist?
  end

  def download
    logger&.info "Downloading #{ filename }..."

    response = HTTParty.get(url)
    raise ScriptNotFound, StaticScript::HELLOBAR_SCRIPT_VERSION unless response.success?

    store_locally response.to_s
  end

  def store_locally(content)
    File.open(local_path, 'wb') { |f| f.puts(content) }
  end

  def local_path
    Rails.root.join('public', 'generated_scripts', filename)
  end

  def url
    "https://s3.amazonaws.com/#{ Settings.s3_bucket }/#{ filename }"
  end

  def filename
    @filename ||= StaticScript::HELLOBAR_SCRIPT_NAME
  end
end
