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

  def inject_data(template)
    template['$INJECT_DATA'] = model.to_json
    template
  end

  def inject_modules(template)
    template['$INJECT_MODULES'] = render_asset 'modules.js'
    template
  end

  def template
    render_asset self.class.template
  end

  def render_asset(*path)
    if options[:compress]
      StaticScriptAssets.render_compressed(*path, site_id: model.site_id)
    else
      StaticScriptAssets.render(*path, site_id: model.site_id)
    end
  end
end
