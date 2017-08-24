class RenderStaticScript
  cattr_reader(:template) { 'static_script_template.js' }

  attr_reader :model, :options

  def initialize(site, options = {})
    @model = StaticScriptModel.new(site, options)
    @options = options
  end

  def call
    render
  end

  private

  def render
    escape_script_tag inject_modules inject_data template
  end

  def escape_script_tag(template)
    template.gsub('</script>', '<\/script>')
  end

  # replace $INJECT_DATA with json settings
  #
  # String#[]= is used here intentional cause
  # `sub` has different behaviour
  # for example `sub` deletes escaped chars like `\\e602`
  def inject_data(template)
    template['$INJECT_DATA'] = model.to_json
    template
  end

  # replace $INJECT_MODULES with something like
  # "https://my.hellobar.com/modules-a3865d95d1e68a2f017fc3a84a71a5adc12d278f230d94e18134ad546aa7aac5.js"
  def inject_modules(template)
    template['$INJECT_MODULES'] = url_for_modules.inspect
    template
  end

  def template
    render_asset self.class.template
  end

  def url_for_modules
    if Settings.store_site_scripts_locally
      "/generated_scripts/#{ path_for_modules }"
    elsif Settings.script_cdn_url.present?
      "https://#{ Settings.script_cdn_url }/#{ path_for_modules }"
    elsif Settings.s3_bucket.present?
      "https://s3.amazonaws.com/#{ Settings.s3_bucket }/#{ path_for_modules }"
    else
      raise 'Could not determine url for modules.js'
    end
  end

  def path_for_modules
    StaticScriptAssets.digest_path('modules.js')
  end

  def render_asset(*path)
    if options[:compress]
      StaticScriptAssets.render_compressed(*path, site_id: model.site_id)
    else
      StaticScriptAssets.render(*path, site_id: model.site_id)
    end
  end
end
