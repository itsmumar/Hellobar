module StaticScriptAssets
  mattr_reader(:uglifier) { Uglifier.new(output: { inline_script: true, comments: :none }) }
  private :uglifier

  mattr_reader(:jbuilder) do
    ActionController::Base.new.view_context.tap do |context|
      context.formats = [:json]
    end
  end
  private :jbuilder

  mattr_reader(:env) do
    Sprockets::Environment.new(Rails.root) do |env|
      env.append_path 'vendor/assets/javascripts/modules'
      env.append_path 'vendor/assets/javascripts/hellobar_script'

      env.append_path 'vendor/assets/stylesheets/site_elements'
      env.append_path 'lib/themes/templates'
      env.append_path 'lib/themes'
      env.append_path 'lib/script_generator'

      env.version = '1.0'
      env.css_compressor = :scss
      env.js_compressor = nil
      env.cache = Rails.cache
    end
  end

  delegate :compress, to: :uglifier
  module_function :compress

  module_function

  def precompile
    manifest(precompiled: false).clobber
    manifest(precompiled: false).compile('*.js', '*.es6', '*.css', '*.html')
  end

  def manifest(precompiled: false)
    Sprockets::Manifest.new(precompiled ? nil : env.index, 'tmp/script')
  end

  # try to render asset from app's assets
  # if an asset is not found either
  # calls given block or raises StandardError
  def render(*path, site_id: nil)
    file = File.join(*path)
    asset = asset(file)
    return asset.toutf8 if asset
    raise Sprockets::FileNotFound, "couldn't find file '#{ file }' for site ##{ site_id }"
  rescue Sass::SyntaxError => e
    e.sass_template ||= path.join('/')
    raise e
  end

  def asset(file, precompiled: false)
    precompiled ||= Rails.env.production?
    manifest(precompiled: precompiled).find_sources(file).first
  rescue TypeError
    nil
  end

  def render_json(*path, **locals)
    jbuilder.render(path.join('/'), **locals)
  end
end
