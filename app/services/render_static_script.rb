require 'digest/sha1'
require 'hmac-sha1'
require 'hmac-sha2'

class RenderStaticScript < Mustache
  self.raise_on_context_miss = true
  self.template_file = Rails.root.join('lib', 'script_generator', 'template.js').to_s

  attr_reader :model, :options

  def initialize(site, options = {})
    @model = StaticScriptModel.new(site, options)
    @options = options
    context.push(model)
  end

  def call
    compile_template

    if options[:compress]
      StaticScriptAssets.compress(render)
    else
      render
    end
  end

  def core_js
    render_asset 'core.js'
  end

  def modules_js
    render_asset 'modules.js'
  end

  def data
    model.to_json
  end

  private

  def compile_template
    @template = nil if Rails.env.development?
    template
  end

  def render_asset(*path)
    StaticScriptAssets.render(*path, site_id: model.site_id)
  end
end
