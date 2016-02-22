require 'digest/sha1'
require "hmac-sha1"
require "hmac-sha2"

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

  # returns the sites tz offset as "+/-HH:MM"
  def site_timezone
    Time.use_zone(site.timezone) do
      Time.zone.formatted_offset
    end
  end

  # This is used to rename the CSS class for the branding so users can not
  # create their own CSS easily to target the branding
  def pro_secret
    @pro_secret ||= begin
      if @options[:preview]
        "hellobar"
      else
        random_string = ('a'..'z').to_a[rand(26)]
        random_string << Digest::SHA1.hexdigest("#{rand(1_000_000)}#{site.url.to_s.upcase}#{site.id}#{Time.now.to_f}#{rand(1_000_000)}")
        random_string
      end
    end
  end

  def capabilities
    {
      no_b: @site.capabilities.remove_branding? || @options[:preview],
      b_variation: get_branding_variation,
      preview: @options[:preview],
      in_bar_ad_fraction: @site.show_in_bar_ads? ? Site.in_bar_ads_config[:show_to_fraction] : 0.0
    }
  end

  def get_branding_variation
    # Options are ["original", "add_hb", "not_using_hb", "powered_by", "gethb", "animated"]
    "animated"
  end

  def capabilities_json
    capabilities.to_json
  end

  def site_write_key
    site.write_key
  end

  def hb_backend_host
    Hellobar::Settings[:tracking_host]
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

  def ie_shims_js
    File.read("#{Rails.root}/vendor/assets/javascripts/hellobar_script/ie_shims.js")
  end

  def crypto_js
    File.read("#{Rails.root}/vendor/assets/javascripts/hellobar_script/crypto.js")
  end

  def hellobar_container_css
    css = File.read "#{Rails.root}/vendor/assets/stylesheets/site_elements/container_common.css"
    klasses = @options[:preview] ? SiteElement::TYPES : all_site_elements.map(&:class).uniq
    css << "\n" << klasses.map { |x| site_element_css(x, true) }.join("\n")

    css = css.gsub("hellobar-container", "#{pro_secret}-container")

    CSSMin.minify(css).to_json
  end

  def hellobar_element_css
    css = File.read "#{Rails.root}/vendor/assets/stylesheets/site_elements/common.css"
    klasses = @options[:preview] ? SiteElement::TYPES : all_site_elements.map(&:class).uniq
    klasses.each { |x| css << "\n" << site_element_css(x) }

    CSSMin.minify(css).to_json
  end

  def site_element_css(element_class, container=false)
    file = "#{Rails.root}/vendor/assets/stylesheets/site_elements/#{element_class.name.downcase}/"
    file << (container ? "container.css" : "element.css")

    if File.exist?(file)
      f = File.read(file)
      return f unless f.blank?
    end
    ""
  end

  def branding_templates
    [].tap do |r|
      Dir.glob("#{Rails.root}/lib/script_generator/branding/*.html") do |f|
        ActiveSupport.escape_html_entities_in_json = false
        content = File.read(f).to_json
        ActiveSupport.escape_html_entities_in_json = true
        r << {name: f.split(".html").first.split("/").last, markup: content}
      end
    end
  end

  def templates
    template_names = Set.new
    if options[:templates]
      options[:templates].each { |t| template_names << t.split("_", 2) }
    else
      site.site_elements.active.each do |se|
        template_names << [se.class.name.downcase, se.element_subtype]
        template_names << [se.class.name.downcase, 'question'] if se.use_question?
      end
    end

    # Add traffic version of each template for ads
    types = Set.new
    template_names.each {|(type, subtype)| types << type }
    types.each do |type|
      template_names << [type, 'traffic']
    end

    template_names.map do |name|
      {
        name: name.join('_'),
        markup: content_template(name[0], name[1])
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
    rule.conditions.map{|c| condition_settings(c)}
  end

  def condition_settings(condition)
    segment = condition.segment == 'CustomCondition' ? condition.custom_segment : condition.segment_key
    {
      segment: segment,
      operand: condition.operand,
      value: condition.value
    }
  end

  def content_template(element_class, type)
    ActiveSupport.escape_html_entities_in_json = false
    content = (content_header(element_class) + content_markup(element_class, type) + content_footer(element_class)).to_json
    ActiveSupport.escape_html_entities_in_json = true

    content
  end

  def content_header(element_class)
    File.read("#{Rails.root}/lib/script_generator/#{element_class}/header.html")
  end

  def content_markup(element_class, type)
    fname = "#{Rails.root}/lib/script_generator/#{element_class}/#{type.gsub("/", "_").underscore}.html"
    if File.exist?(fname)
      File.read(fname)
    else
      File.read("#{Rails.root}/lib/script_generator/#{type.gsub("/", "_").underscore}.html")
    end
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
      font
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
      type
      view_condition
      wiggle_button
      wordpress_bar_id
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

      branding_url: "http://www.hellobar.com?sid=#{site_element.id}",
      closable: site_element.is_a?(Bar) ? site_element.closable : false,
      contact_list_id: site_element.contact_list_id,
      conversion_rate: conversion_rate,
      conversions: conversions,
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
      tab_side: "right",
      target: site_element.target_segment,
      template_name: "#{site_element.class.name.downcase}_#{site_element.element_subtype}",
      thank_you_text: SiteElement.sanitize(site_element.display_thank_you_text).gsub(/"/, "&quot;"),
      views: views,
      updated_at: site_element.updated_at.to_f * 1000,
      use_free_email_default_msg: site_element.show_default_email_message? && site_element.site.is_free?,
      wiggle_wait: 0
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
end
