class GenerateStaticScriptModules
  MODULES_FILENAME = 'modules.js'.freeze

  def call
    compile
    if store_site_scripts_locally?
      store_locally
    else
      store_remotely
    end
  end

  private

  attr_reader :site, :compress, :script_content

  def compile
    @script_content ||= begin
      StaticScriptAssets.compile(MODULES_FILENAME)
      if compress_script?
        StaticScriptAssets.render_compressed(MODULES_FILENAME)
      else
        StaticScriptAssets.render(MODULES_FILENAME)
      end
    end
  end

  def store_locally
    File.open(local_path, 'w') { |f| f.puts(script_content) }
  end

  def store_remotely
    UploadToS3.new(filename, script_content, cache: 1.year).call
  end

  def compress_script?
    !store_site_scripts_locally?
  end

  def local_path
    Rails.root.join('public', 'generated_scripts', filename)
  end

  def filename
    @filename ||= StaticScriptAssets.digest_path(MODULES_FILENAME)
  end

  def store_site_scripts_locally?
    Settings.store_site_scripts_locally
  end
end
