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
    Digest::SHA1.hexdigest("#{rand(1_000_000)}#{site.url.to_s.upcase}#{site.id}#{Time.now.to_f}#{rand(1_000_000)}")
  end

  def capabilities
    {
      no_b: @site.capabilities.remove_branding? || @options[:preview]
    }
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

  def hellobar_base_js
    File.read("#{Rails.root}/vendor/assets/javascripts/hellobar.base.js")
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
    template_names = options[:templates] || site.site_elements.active.map(&:element_subtype).uniq

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
    rule.conditions.map{|c| condition_settings(c)}
  end

  def condition_settings(condition)
    {
      segment: condition.segment_key,
      operand: condition.operand,
      value: condition.value
    }
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
    settings = %w{ closable show_border background_color border_color button_color font link_color link_style link_text message size target text_color texture show_branding}

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

    thank_you_text = if @site.capabilities.custom_thank_you_text? && site_element.thank_you_text.present?
                       site_element.thank_you_text
                     else
                       "Thank you for signing up!"
                     end

    site_element.attributes.select{|key,val| settings.include?(key) }.merge({
      id: site_element.id,
      views: views,
      conversions: conversions,
      conversion_rate: conversion_rate,
      contact_list_id: site_element.contact_list_id,
      target: site_element.target_segment,
      template_name: site_element.element_subtype,
      type: site_element.short_subtype,
      settings: site_element.settings,
      hide_destination: true,
      open_in_new_window: site_element.open_in_new_window,
      pushes_page_down: site_element.pushes_page_down,
      remains_at_top: site_element.remains_at_top,
      wiggle_wait: 0,
      tab_side: "right",
      thank_you_text: SiteElement.sanitize(thank_you_text).gsub(/"/, "&quot;")
    }).select{|key, value| !value.nil? || !value == '' }
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
end
