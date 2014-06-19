class ScriptGenerator < Mustache
  self.template_path = "#{Rails.root}/lib/script_generator/"
  self.template_file = "#{Rails.root}/lib/script_generator/template.js.mustache"

  attr_reader :site, :options

  def initialize(site, options={})
    @site = site
    @options = options
  end

  def generate_script
    if options[:compress]
      Uglifier.new.compress(render)
    else
      render
    end
  end

  def site_id
    site.id
  end

  def hb_backend_host
    Hellobar::Settings[:tracking_host]
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

  def templates
    site.bars.active.group_by(&:bar_type).map do |type, bars|
      {
        name: type,
        markup: content_template(type)
      }
    end
  end

  def rules
    site.rules.map{|rule| hash_for_rule(rule) }
  end

private

  def hash_for_rule(rule)
    {
      bar_json: bars_for_rule(rule).to_json,
      priority: 1, # seems to be hardcoded as 1 throughout WWW
      metadata: metadata(rule).to_json
    }.merge(eligibility_rules(rule))
  end

  def eligibility_rules(rule)
    if options[:disable_eligibility]
      {}
    else
      {
        rule_eligibility: condition_string(rule.match, rule.conditions)
      }
    end
  end

  def condition_string(match, conditions)
    join_operator = match == Rule::MATCH_ON[:all] ? '&&' : '||'

    string = conditions.map do |condition|
      if condition.kind_of?(DateCondition)
        date_conditions(condition)
      elsif condition.kind_of?(UrlCondition)
        url_conditions(condition)
      end
    end.join(join_operator)

    if string.present?
      "return #{string};}"
    else
      'return true;}'
    end
  end

  def date_conditions(condition)
    if condition.value.has_key?('start_date') && condition.value.has_key?('end_date')
      "((new Date()).getTime()/1000 > #{condition.value['start_date'].to_i}) && ((new Date()).getTime()/1000 < #{condition.value['end_date'].to_i})"
    elsif condition.value.has_key?('start_date')
      "((new Date()).getTime()/1000 > #{condition.value['start_date'].to_i})"
    elsif condition.value.has_key?('end_date')
      "((new Date()).getTime()/1000 < #{condition.value['end_date'].to_i})"
    end
  end

  def url_conditions(condition)
    bang = condition.value.has_key?('include_url') ? '' : '!'

    "(#{bang}HB.umatch(\"#{condition.url}\", document.location))"
  end

  def content_template(bar_type)
    ActiveSupport.escape_html_entities_in_json = false
    content = (content_header + content_markup(bar_type) + content_footer).to_json
    ActiveSupport.escape_html_entities_in_json = true

    content
  end

  def content_header
    @content_header ||= File.read("#{Rails.root}/lib/script_generator/bar_header.html")
  end

  def content_markup(bar_type)
    File.read("#{Rails.root}/lib/script_generator/bar_#{bar_type.gsub("/", "_").underscore}.html")
  end

  def content_footer
    @content_footer ||= File.read("#{Rails.root}/lib/script_generator/bar_footer.html")
  end

  def bar_settings(bar)
    settings = %w{ closable hide_destination open_in_new_window pushes_page_down remains_at_top show_border hide_after show_wait wiggle_wait bar_color border_color button_color font link_color link_style link_text message size tab_side target text_color texture thank_you_text }

    bar.attributes.select{|key,val| settings.include?(key) }.merge({
      id: bar.id,
      target: bar.target_segment,
      template_name: bar.bar_type,
      settings: bar.settings
    }).select{|key, value| !value.nil? || !value == '' }
  end

  def rule_settings(rule)
    settings = %w{ end_date start_date exclude_urls include_urls id }

    rule.attributes.select{|key, value| settings.include?(key) && value.present? }
  end

  def bars_for_rule(rule)
    bars = if options[:bar_id]
      [rule.bars.find(options[:bar_id])]
    else
      if options[:render_paused_bars]
        rule.bars
      else
        rule.bars.active
      end
    end

    bars.map{|bar| bar_settings(bar) }
  end

  def metadata(rule)
    rule_settings(rule).select{|key,value| value.present? }.with_indifferent_access
  end
end
