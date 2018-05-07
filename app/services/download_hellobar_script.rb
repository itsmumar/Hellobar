class DownloadHellobarScript
  cattr_accessor :logger do
    Logger.new(STDOUT).tap do |logger|
      logger.formatter = proc { |severity, datetime, progname, msg| "#{ msg }\n" }
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
    logger.info "Downloading #{ filename }..." if logger

    object = s3.get_object(
      bucket: Settings.s3_bucket,
      key: filename
    )

    unzip object.body, &method(:store_locally)
  end

  def unzip(io)
    gzipped = Zlib::GzipReader.new(io)
    yield gzipped.read
    gzipped.close
  rescue Zlib::GzipFile::Error
    io.rewind
    yield io.read
  end

  def store_locally(content)
    File.open(local_path, 'wb') { |f| f.puts(content) }
  end

  def local_path
    Rails.root.join('public', 'generated_scripts', filename)
  end

  def filename
    @filename ||= StaticScript::HELLOBAR_SCRIPT_NAME
  end

  def s3
    Aws::S3::Client.new
  end
end
