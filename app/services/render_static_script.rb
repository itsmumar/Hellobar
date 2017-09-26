class RenderStaticScript
  cattr_reader(:template) { 'static_script_template.js' }

  attr_reader :model, :script, :options

  def initialize(site, options = {})
    @model = StaticScriptModel.new(site, options)
    @script = StaticScript.new(site)
    @options = options
  end

  def call
    render
  end

  private

  def render
    inject_modules inject_data template
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
    template['$INJECT_MODULES'] = script.modules_url.inspect
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
