module StaticScriptAssets
  mattr_reader(:uglifier) { Uglifier.new(output: { inline_script: true, comments: :none }) }

  mattr_reader(:jbuilder) do
    ActionController::Base.new.view_context.tap do |context|
      context.formats = [:json]
    end
  end

  mattr_reader(:env) do
    Sprockets::Environment.new(Rails.root) do |env|
      env.append_path 'vendor/assets/javascripts/modules'
      env.append_path 'vendor/assets/javascripts/hellobar_script'
      env.append_path 'vendor/assets/stylesheets/site_elements'

      env.append_path 'lib/themes/templates'
      env.append_path 'lib/themes'
      env.append_path 'lib/script_generator'

      env.version = '1.0'
      env.gzip = false
      env.css_compressor = :scss
      env.js_compressor = nil
      env.cache = Rails.cache
    end
  end

  mattr_reader(:manifest) { Sprockets::Manifest.new(env, 'tmp/script') }

  module_function

  def precompile
    manifest.clobber
    with_js_compressor { manifest.compile('*.js', '*.es6', '*.css', '*.html') }
  end

  def with_js_compressor
    env.js_compressor = uglifier
    yield
  ensure
    env.js_compressor = nil
  end

  def digest_path(*path, site_id: nil)
    manifest.assets[File.join(path)] ||
      raise(Sprockets::FileNotFound, "couldn't find file '#{ file }' for site ##{ site_id }")
  end

  # @param [Array[String]] *path
  # @option [Integer] site_id:
  # @raises Sprockets::FileNotFound
  def render(*path, site_id: nil)
    file = File.join(*path)
    asset = manifest.find_sources(file).first
    return asset.toutf8 if asset
    raise Sprockets::FileNotFound, "couldn't find file '#{ file }' for site ##{ site_id }"
  rescue Sass::SyntaxError => e
    e.sass_template ||= path.join('/')
    raise e
  end

  def render_compressed(*args)
    with_js_compressor { render(*args) }
  end

  def render_model(model)
    jbuilder.render model.to_partial_path, model: model
  end
end
