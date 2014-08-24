class ScriptGenerator < Mustache
  class << self
    def load_templates
      self.template_path = "#{Rails.root}/lib/script_generator/"
      self.template_file = "#{Rails.root}/lib/script_generator/template.js.mustache"
    end
  end
  load_templates

  attr_reader :site, :options

  def initialize(site, options={})
    @site = site
    @options = options
  end

  def generate_script
    if Rails.env.development?
      # Re-read the template
      ScriptGenerator.load_templates
    end
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
    template_names = options[:templates] || site.site_elements.active.map.map(&:element_subtype).uniq

    template_names.map do |name|
      {
        name: name,
        markup: content_template(name)
      }
    end
  end

  def rules
    options[:rules] || site.rules.map{|rule| hash_for_rule(rule) }
  end

private

  def hash_for_rule(rule)
    {
      match: rule.match,
      conditions: conditions_for_rule(rule).to_json,
      site_elements: site_elements_for_rule(rule).to_json
    }
  end
  
  def conditions_for_rule(rule)
    rule.conditions
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
      elsif condition.kind_of?(CountryCondition)
        # TODO: how do we get the current users country
      elsif condition.kind_of?(DeviceCondition)
        # TODO: how do we get the current users device?
      else
        raise "unhandled condition type: #{condition.segment}"
      end
    end.join(join_operator)

    if string.present?
      "return #{string};}"
    else
      'return true;}'
    end
  end

  def date_conditions(condition)
    tz = condition.value['timezone']
    conditions = Array.new.tap do |array|
      if start_date = condition.comparable_start_date
        array << %{(HB.comparableDate(#{'"auto"' unless tz}) >= "#{start_date}")}
      end

      if end_date = condition.comparable_end_date
        array << %{(HB.comparableDate(#{'"auto"' unless tz}) <= "#{end_date}")}
      end
    end

    conditions.join('&&')
  end

  def url_conditions(condition)
    bang = condition.include_url? ? '' : '!'

    "(#{bang}HB.umatch(\"#{path_for_url(condition.value)}\", document.location))"
  end

  def path_for_url(url)
    path = Addressable::URI.heuristic_parse(url).path
    path.gsub!(/\/+$/, "") # strip trailing slashes
    path.blank? ? "/" : path
  rescue Addressable::URI::InvalidURIError
    url
  end

  def content_template(element_subtype)
    ActiveSupport.escape_html_entities_in_json = false
    content = (content_header + content_markup(element_subtype) + content_footer).to_json
    ActiveSupport.escape_html_entities_in_json = true

    content
  end

  def content_header
    @content_header ||= File.read("#{Rails.root}/lib/script_generator/bar_header.html")
  end

  def content_markup(element_subtype)
    File.read("#{Rails.root}/lib/script_generator/bar_#{element_subtype.gsub("/", "_").underscore}.html")
  end

  def content_footer
    @content_footer ||= File.read("#{Rails.root}/lib/script_generator/bar_footer.html")
  end

  def site_element_settings(site_element)
    settings = %w{ closable show_border hide_after show_wait background_color border_color button_color font link_color link_style link_text message size target text_color texture }

    site_element.attributes.select{|key,val| settings.include?(key) }.merge({
      id: site_element.id,
      contact_list_id: site_element.contact_list_id,
      target: site_element.target_segment,
      template_name: site_element.element_subtype,
      settings: site_element.settings,
      hide_destination: true,
      open_in_new_window: false,
      pushes_page_down: true,
      remains_at_top: true,
      wiggle_wait: 0,
      tab_side: "right",
      thank_you_text: "Thank you for signing up!"
    }).select{|key, value| !value.nil? || !value == '' }
  end

  def rule_settings(rule)
    settings = %w{ end_date start_date exclude_urls include_urls id }

    rule.attributes.select{|key, value| settings.include?(key) && value.present? }
  end

  def site_elements_for_rule(rule)
    site_elements = if options[:bar_id]
      [rule.site_elements.find(options[:bar_id])]
    else
      if options[:render_paused_site_elements]
        rule.site_elements
      else
        rule.site_elements.active
      end
    end

    site_elements.map{|element| site_element_settings(element) }
  end

  def metadata(rule)
    rule_settings(rule).select{|key,value| value.present? }.with_indifferent_access
  end
end
