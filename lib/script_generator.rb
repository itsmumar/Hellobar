class ScriptGenerator < Mustache
  self.template_path = "#{Rails.root}/lib/script_generator/"
  self.template_file = "#{Rails.root}/lib/script_generator/template.js.mustache"

  attr_reader :site, :config

  def initialize(site, config, options={})
    @site = site
    @config = config
  end

  def site_id
    site.id
  end

  def hb_backend_host
    config.hb_backend_host
  end

  def hellobar_base_js
    File.read "#{Rails.root}/vendor/assets/javascripts/hellobar.base.js"
  end

  def hellobar_base_css
    file = File.read "#{Rails.root}/vendor/assets/stylesheets/hellobar_script.css"

    CSSMin.minify(file).to_json
  end

  def hellobar_container_css
    file = File.read "#{Rails.root}/vendor/assets/stylesheets/hellobar_script_container.css"

    CSSMin.minify(file).to_json
  end

  # TODO: populate correct hash
  def templates
    [
      { name: 'name',
        markup: '<html>'
      }
    ]
  end

  def rules
    site.rules.map do |rule|
      {
        bars: [rule],
        priority: 1, # seems to be hardcoded as 1 throughout WWW
        metadata: {
          id: rule.id,
          type: 'type_short_name'
        }
      }
    end
  end

  def rule_start_date(rule_setting)
    if rule_setting.start_date
      rule_setting.start_date.to_i
    end
  end

  def rule_end_date(rule_setting)
    if rule_setting.end_date
      rule_setting.end_date.to_i
    end
  end

private

  def start_time_constraint(start_time)
    # TODO: refactor JS
    # "if(new Date().getTime() < Date.parse(#{start_time.utc})) return false;"
  end

  def end_time_constraint(end_time)
    # TODO: refactor JS
    # "if(new Date().getTime() > Date.parse(#{end_time.utc})) return false;"
  end

  def compress_content
    #
  end

  def uglify_content
    #
  end
end
