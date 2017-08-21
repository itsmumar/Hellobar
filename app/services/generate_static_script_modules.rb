class GenerateStaticScriptModules
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
    @script_content ||=
      if compress_script?
        StaticScriptAssets.render_compressed('modules.js')
      else
        StaticScriptAssets.render('modules.js')
      end
  end

  def store_locally
    File.open(local_path, 'w') { |f| f.puts(script_content) }
  end

  def store_remotely
    UploadToS3.new(filename, script_content).call
  end

  def compress_script?
    !store_site_scripts_locally?
  end

  def local_path
    Rails.root.join('public', 'generated_scripts', filename)
  end

  def filename
    @filename ||= StaticScriptAssets.digest_path('modules.js')
  end

  def store_site_scripts_locally?
    Settings.store_site_scripts_locally
  end
end
