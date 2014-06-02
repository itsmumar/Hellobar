class ScriptGenerator < Mustache
  self.template_path = "#{Rails.root}/lib/script_generator/"
  self.template_file = "#{Rails.root}/lib/script_generator/template.js.mustache"

  attr_reader :site, :config, :options

  def initialize(site, config, options={})
    @site = site
    @config = config
    @options = options
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

  def templates
    site.bars.map do |bar|
      {
        name: bar.goal,
        markup: content_template(bar.goal)
      }
    end
  end

  def rules
    site.rules.map{|rule| hash_for_rule(rule) }
  end

private

  def hash_for_rule(rule)
    {
      bars: bars_for_rule(rule),
      priority: 1, # seems to be hardcoded as 1 throughout WWW
      metadata: metadata(rule)
    }.merge(eligibility_rules(rule))
  end

  def eligibility_rules(rule)
    if options[:disable_eligibility]
      {}
    else
      {
        start_date: rule_start_date(rule),
        end_date: rule_end_date(rule),
        exclude_urls: rule.exclude_urls,
        include_urls: rule.include_urls
      }
    end
  end

  def content_template(goal)
    (content_header << content_markup(goal) << content_footer).to_json
  end

  def content_header
    @content_header ||= File.read("#{Rails.root}/lib/script_generator/bar_header.html")
  end

  def content_markup(goal)
    File.read("#{Rails.root}/lib/script_generator/bar_#{goal.underscore}.html")
  end

  def content_footer
    @content_footer ||= File.read("#{Rails.root}/lib/script_generator/bar_footer.html")
  end

  def rule_start_date(rule)
    rule.start_date.to_i if rule.start_date
  end

  def rule_end_date(rule)
    rule.end_date.to_i if rule.end_date
  end

  def bar_settings(bar)
    settings = %w{ closable hide_destination open_in_new_window pushes_page_down remains_at_top show_border hide_after show_wait wiggle_wait bar_color border_color button_color font link_color link_style link_text message size tab_side target text_color texture thank_you_text }

    bar.attributes.select{|key,val| settings.include?(key) }.merge({
      id: bar.id,
      target: bar.target_segment,
      template_name: bar.goal
    }).select{|key, value| value.present? }
  end

  def rule_settings(rule)
    settings = %w{ end_date start_date exclude_urls include_urls id }

    rule.attributes.select{|key, value| settings.include?(key) }
  end

  # FIXME: if bar_id is present, bars will not be ennumerable
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

    bars.map{|bar| { bar_json: bar_settings(bar) }}
  end

  # Previous metadata keys. TODO: figure this out.
  # ["url", "exclude_urls", "include_urls", "dates_timezone", "end_date", "start_date", "collect_names", "interaction", "interaction_description", "url_to_tweet", "pinterest_url", "pinterest_image_url", "pinterest_description", "message_to_tweet", "url_to_like", "url_to_share", "twitter_handle", "use_location_for_url", "url_to_plus_one", "pinterest_user_url", "pinterest_full_name", "buffer_message", "buffer_url"]
  # we killed the type key, so ignore from old generated script files
  def metadata(rule)
    rule_settings(rule).select{|k,v| v.present? }.with_indifferent_access
  end
end
