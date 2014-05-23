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

      # this was previously the Goal#id. How do backfill?
      metadata: metadata(rule)
    }.merge(eligibility_rules)
  end

  def eligibility_rules
    if options[:disable_eligibility]
      {}
    else
      {
        start_date: rule_start_date(rule.rule_setting),
        end_date: rule_end_date(rule.rule_setting),
        exclude_urls: rule.rule_setting.exclude_urls,
        include_urls: rule.rule_setting.include_urls
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

  def bars_for_rule(rule)
    rule.bars.map do |bar|
      {
        bar_json: bar.public_attributes_with_settings.select{|k,v| v.present?} # guard against nil
      }
    end
  end

  # Previous metadata keys. TODO: figure this out.
  # ["url", "exclude_urls", "include_urls", "dates_timezone", "end_date", "start_date", "collect_names", "interaction", "interaction_description", "url_to_tweet", "pinterest_url", "pinterest_image_url", "pinterest_description", "message_to_tweet", "url_to_like", "url_to_share", "twitter_handle", "use_location_for_url", "url_to_plus_one", "pinterest_user_url", "pinterest_full_name", "buffer_message", "buffer_url"]
  # we killed the type key, so ignore from old generated script files
  def metadata(rule)
    available_settings = rule.rule_setting.public_attributes.select{|k,v| v.present? }
    available_settings.merge(id: rule.id).with_indifferent_access
  end
end
