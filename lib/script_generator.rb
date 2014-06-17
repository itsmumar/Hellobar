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
    site.bars.active.map do |bar|
      {
        name: bar.bar_type,
        markup: content_template(bar.bar_type)
      }
    end
  end

  def rule_sets
    site.rule_sets.map{|rule_set| hash_for_rule_set(rule_set) }
  end

private

  def hash_for_rule_set(rule_set)
    {
      bar_json: bars_for_rule_set(rule_set).to_json,
      priority: 1, # seems to be hardcoded as 1 throughout WWW
      metadata: metadata(rule_set).to_json
    }.merge(eligibility_rules(rule_set))
  end

  def eligibility_rules(rule_set)
    if options[:disable_eligibility]
      {}
    else
      date_condition = rule_set.conditions.where(type: 'DateCondition').first || Condition.new(value: {})
      url_condition = rule_set.conditions.where(type: 'UrlCondition').first || Condition.new(value: {})

      {
        start_date: condition_start_date(date_condition),
        end_date: condition_end_date(date_condition),
        exclude_urls: url_condition.value['exclude_urls'],
        include_urls: url_condition.value['include_urls']
      }
    end
  end

  def content_template(bar_type)
    ActiveSupport.escape_html_entities_in_json = false
    content = (content_header << content_markup(bar_type) << content_footer).to_json
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

  def condition_start_date(condition)
    condition.value['start_date'].to_i if condition.value['start_date']
  end

  def condition_end_date(condition)
    condition.value['end_date'].to_i if condition.value['end_date']
  end

  def bar_settings(bar)
    settings = %w{ closable hide_destination open_in_new_window pushes_page_down remains_at_top show_border hide_after show_wait wiggle_wait bar_color border_color button_color font link_color link_style link_text message size tab_side target text_color texture thank_you_text }

    bar.attributes.select{|key,val| settings.include?(key) }.merge({
      id: bar.id,
      target: bar.target_segment,
      template_name: bar.bar_type,
      settings: bar.settings
    }).select{|key, value| value.present? }
  end

  def rule_set_settings(rule_set)
    settings = %w{ end_date start_date exclude_urls include_urls id }

    rule_set.attributes.select{|key, value| settings.include?(key) && value.present? }
  end

  # FIXME: if bar_id is present, bars will not be ennumerable
  def bars_for_rule_set(rule_set)
    bars = if options[:bar_id]
      [rule_set.bars.find(options[:bar_id])]
    else
      if options[:render_paused_bars]
        rule_set.bars
      else
        rule_set.bars.active
      end
    end

    bars.map{|bar| bar_settings(bar) }
  end

  def metadata(rule_set)
    rule_set_settings(rule_set).select{|k,v| v.present? }.with_indifferent_access
  end
end
