require 'digest/sha1'
require 'hmac-sha1'
require 'hmac-sha2'

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

  def site_url
    site.url
  end

  def script_is_installed_properly
    if Rails.env.test?
      true
    else
      'HB.scriptIsInstalledProperly()'
    end
  end

  # returns the sites tz offset as "+/-HH:MM"
  def site_timezone
    Time.use_zone(site.timezone) do
      Time.zone.now.formatted_offset
    end
  end

  # This is used to rename the CSS class for the branding so users can not
  # create their own CSS easily to target the branding
  def pro_secret
    @pro_secret ||= begin
      random_string = ('a'..'z').to_a[rand(26)]
      random_string << Digest::SHA1.hexdigest("#{rand(1_000_000)}#{site.url.to_s.upcase}#{site.id}#{Time.now.to_f}#{rand(1_000_000)}")
      random_string
    end
  end

  def capabilities
    {
      no_b: @site.capabilities.remove_branding? || @options[:preview],
      b_variation: get_branding_variation,
      preview: @options[:preview]
    }
  end

  def get_branding_variation
    # Options are ["original", "add_hb", "not_using_hb", "powered_by", "gethb", "animated"]
    'animated'
  end

  def capabilities_json
    capabilities.to_json
  end

  def content_upgrades_json
    cu_json = {}
    site.site_elements.active_content_upgrades.each do |cu|
      content = {
        id: cu.id,
        type: 'ContentUpgrade',
        offer_headline: cu.offer_headline.to_s.gsub('{{','<a href="#">').gsub('}}','</a>'),
        caption: cu.caption,
        headline: cu.headline,
        disclaimer: cu.disclaimer,
        link_text: cu.link_text,
        email_placeholder: cu.email_placeholder,
        name_placeholder: cu.name_placeholder,
        contact_list_id: cu.contact_list_id,
        download_link: cu.content_upgrade_download_link      }
      cu_json[cu.id] = content
    end
    cu_json.to_json
  end

  def content_upgrades_styles_json
    site.get_content_upgrade_styles.to_json
  end

  def site_write_key
    site.write_key
  end

  def hb_backend_host
    Hellobar::Settings[:tracking_host]
  end

  def geolocation_url
    Hellobar::Settings[:geolocation_url]
  end

  def site_element_classes_js
    js = File.read("#{Rails.root}/vendor/assets/javascripts/site_elements/site_element.js")

    klasses = @options[:preview] ? SiteElement::TYPES : all_site_elements.map(&:class).uniq
    klasses.each do |klass|
      js << "\n" << File.read("#{Rails.root}/vendor/assets/javascripts/site_elements/#{klass.name.downcase}.js")
    end
    js
  end

  def hellobar_base_js
    File.read("#{Rails.root}/vendor/assets/javascripts/hellobar.base.js")
  end

  def autofills_json
    site.autofills.to_json
  end

  def autofills_js
    File.read("#{Rails.root}/vendor/assets/javascripts/autofills/autofills.js")
  end

  def ie_shims_js
    File.read("#{Rails.root}/vendor/assets/javascripts/hellobar_script/ie_shims.js")
  end

  def crypto_js
    File.read("#{Rails.root}/vendor/assets/javascripts/hellobar_script/crypto.js")
  end

  def jquery_lib
    File.read("#{Rails.root}/vendor/assets/javascripts/jquery-2.2.4.js")
  end

  def hellobar_container_css
    css = read_css_files(container_css_files)
    css = css.gsub('hellobar-container', "#{pro_secret}-container")

    CSSMin.minify(css).to_json
  end

  def hellobar_element_css
    css = read_css_files(element_css_files)
    CSSMin.minify(css).to_json
  end

  def branding_templates
    [].tap do |r|
      Dir.glob("#{Rails.root}/lib/script_generator/branding/*.html") do |f|
        ActiveSupport.escape_html_entities_in_json = false
        content = File.read(f).to_json
        ActiveSupport.escape_html_entities_in_json = true
        r << {name: f.split('.html').first.split('/').last, markup: content}
      end
    end
  end

  def content_upgrade_template
    [].tap do |r|
      f = "#{Rails.root}/lib/script_generator/contentupgrade/contentupgrade.html"
      ActiveSupport.escape_html_entities_in_json = false
      content = File.read(f).to_json
      ActiveSupport.escape_html_entities_in_json = true
      r << {name: f.split('.html').first.split('/').last, markup: content}
    end
  end

  def templates
    template_names = Set.new

    if options[:templates]
      templates = Theme.where(type: 'template').collect(&:name)

      options[:templates].each { |t|
        temp_name = t.split('_', 2)
        category  = :generic
        category  = :template if templates.include?(temp_name[1].titleize)
        template_names << (temp_name << category)
      }
    else
      site.site_elements.active.each do |se|
        theme_id      = se.theme_id
        theme         = Theme.where(id: theme_id).first
        category      = theme.type.to_sym
        subtype       = (category == :template ? theme_id.underscore : se.element_subtype)

        template_names << [se.class.name.downcase, subtype, category]
        template_names << [se.class.name.downcase, 'question', category] if se.use_question?
      end
    end

    template_names.map do |name|
        {
          name: name.first(2).join('_'),
          markup: content_template(name[0], name[1], name[2])
        }
    end
  end

  def rules
    options[:rules] || site.rules.map { |rule| hash_for_rule(rule) }
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
    rule.conditions.map{|c| condition_settings(c)}
  end

  def condition_settings(condition)
    segment = condition.segment == 'CustomCondition' ? condition.custom_segment : condition.segment_key

    settings = {
      segment: segment,
      operand: condition.operand,
      value: condition.value
    }

    if condition.timezone_offset.present?
      settings.merge(timezone_offset: condition.timezone_offset)
    else
      settings
    end
  end

  def content_template(element_class, type, category = :generic)
    ActiveSupport.escape_html_entities_in_json = false

    content = if category == :generic
                (content_header(element_class) +
                  content_markup(element_class, type, category) +
                  content_footer(element_class)).to_json
              else
                content_markup(element_class, type, category).to_json
              end

    ActiveSupport.escape_html_entities_in_json = true

    content
  end

  def content_header(element_class)
    File.read("#{Rails.root}/lib/script_generator/#{element_class}/header.html")
  end

  def content_markup(element_class, type, category = :generic)
    return '' if element_class == 'custom'
    fname = ''

    if category == :generic
      base = "#{Rails.root}/lib/script_generator"
      fname = "#{base}/#{element_class}/#{type.gsub('/', '_').underscore}.html"
      fname = "#{base}/#{type.gsub('/', '_').underscore}.html" unless File.exist?(fname)
    else
      base = "#{Rails.root}/lib/themes/#{category.to_s.pluralize}/#{type.gsub('_', '-')}"
      fname = "#{base}/#{element_class}.html"
      fname = "#{base}/element.html" unless File.exist?(fname)
    end

    File.read(fname)
  end

  def content_footer(element_class)
    File.read("#{Rails.root}/lib/script_generator/#{element_class}/footer.html")
  end

  def site_element_settings(site_element)
    settings = %w{
      animated
      background_color
      border_color
      button_color
      email_placeholder
      headline
      image_placement
      link_color
      link_style
      link_text
      name_placeholder
      phone_number
      placement
      show_border
      show_branding
      size
      target
      text_color
      texture
      theme_id
      type
      view_condition
      wiggle_button
      wordpress_bar_id
      blocks
    }
    settings << 'caption' unless site_element.use_question?

    lifetime_totals = @site.lifetime_totals
    conversion_data = lifetime_totals ? lifetime_totals[site_element.id.to_s] : nil
    views = conversions = conversion_rate = 0

    if conversion_data and conversion_data[0]
      views = conversion_data[0][0]
      conversions = conversion_data[0][1]
      if views > 0
        conversion_rate = ((conversions.to_f/views)*1000).floor.to_f/1000
      end
    end

    site_element.attributes.select{|key,val| settings.include?(key) }.merge({
      answer1: site_element.answer1,
      answer1response: site_element.answer1response,
      answer1caption: site_element.answer1caption,
      answer1link_text: site_element.answer1link_text,
      answer2: site_element.answer2,
      answer2response: site_element.answer2response,
      answer2caption: site_element.answer2caption,
      answer2link_text: site_element.answer2link_text,
      use_question: site_element.use_question,
      question: site_element.question,
      font: site_element.font.value,
      google_font: site_element.font.google_font,
      branding_url: "http://www.hellobar.com?sid=#{site_element.id}",
      closable: site_element.is_a?(Bar) || site_element.is_a?(Slider) ? site_element.closable : false,
      contact_list_id: site_element.contact_list_id,
      conversion_rate: conversion_rate,
      conversions: conversions,
      custom_html: site_element.custom_html,
      custom_css: site_element.custom_css,
      custom_js: site_element.custom_js,
      email_redirect: site_element.after_email_submit_action == :redirect,
      hide_destination: true,
      id: site_element.id,
      image_url: site_element.image_url,
      open_in_new_window: site_element.open_in_new_window,
      phone_number: site_element.phone_number,
      primary_color: site_element.primary_color,
      pushes_page_down: site_element.pushes_page_down,
      remains_at_top: site_element.remains_at_top,
      secondary_color: site_element.secondary_color,
      settings: site_element.settings,
      subtype: site_element.short_subtype,
      tab_side: 'right',
      target: site_element.target_segment,
      template_name: "#{site_element.class.name.downcase}_#{site_element.element_subtype}",
      thank_you_text: SiteElement.sanitize(site_element.display_thank_you_text).gsub(/"/, '&quot;'),
      views: views,
      updated_at: site_element.updated_at.to_f * 1000,
      use_free_email_default_msg: site_element.show_default_email_message? && site_element.site.is_free?,
      wiggle_wait: 0,
      blocks: site_element.blocks,
      theme: site_element.theme.attributes
    }).select{|key, value| !value.nil? || !value == '' }
  end

  def site_elements_for_rule(rule, hashify=true)
    site_elements = if options[:bar_id]
      [rule.site_elements.find(options[:bar_id])]
    else
      if options[:render_paused_site_elements]
        rule.site_elements
      else
        rule.site_elements.active
      end
    end

    hashify ? site_elements.map{|element| site_element_settings(element) } : site_elements
  end

  def all_site_elements
    site.rules.map { |r| site_elements_for_rule(r, false) }.flatten
  end

  def element_classes
    @options[:preview] ? SiteElement::TYPES : all_site_elements.map(&:class).uniq
  end

  def element_themes
    @options[:preview] ? Theme.all : all_site_elements.map(&:theme).compact.uniq
  end

  def container_css_files
    vendor_root = "#{Rails.root}/vendor/assets/stylesheets/site_elements"
    files = ["#{vendor_root}/container_common.css"]

    files += element_classes.map { |klass| "#{vendor_root}/#{klass.name.downcase}/container.css" }
    files += element_themes.map(&:container_css_path)
  end

  def element_css_files
    vendor_root = "#{Rails.root}/vendor/assets/stylesheets/site_elements"
    files = ["#{vendor_root}/common.css"]

    files += element_classes.map { |klass| "#{vendor_root}/#{klass.name.downcase}/element.css" }
    files += element_themes.map(&:element_css_path)
  end

  def read_css_files(files)
    css = files.map do |file|
      next unless File.exist?(file)
      raw_css = File.read(file)
      if file.include?('.scss')
        raw_css = Sass::Engine.new(raw_css, syntax: :scss).render
      end

      raw_css
    end

    css.compact.join("\n")
  end
end
