require 'digest/sha1'
require 'hmac-sha1'
require 'hmac-sha2'

class ScriptGenerator < Mustache
  self.raise_on_context_miss = true
  cattr_reader(:uglifier) { Uglifier.new(output: { inline_script: true, comments: :none }) }

  class << self
    def compile
      FileUtils.rm_r Rails.root.join('tmp', 'script'), force: true
      manifest(true).compile('*.js', '*.css', '*.html')
    end

    def load_templates
      self.template_path = Rails.root.join('lib', 'script_generator')
      self.template_name = 'template.js'
    end

    def assets
      @assets ||= Sprockets::Environment.new(Rails.root) do |env|
        env.append_path 'vendor/assets/javascripts/modules'
        env.append_path 'vendor/assets/javascripts/hellobar_script'
        env.append_path 'vendor/assets/javascripts/site_elements'

        env.append_path 'vendor/assets/stylesheets/site_elements'
        env.append_path 'lib/themes/templates'
        env.append_path 'lib/themes'
        env.append_path 'lib/script_generator'

        env.version = '1.0'
        env.css_compressor = :scss
        env.js_compressor = nil
        env.cache = Rails.cache
      end
    end

    def manifest(fresh = false)
      fresh ||= Rails.env.test?
      Sprockets::Manifest.new(fresh ? assets.index : nil, 'tmp/script')
    end
  end
  load_templates

  attr_reader :site, :options, :manifest
  delegate :id, :url, :write_key, to: :site, prefix: true

  def initialize(site, options = {})
    @site = site
    @options = options
  end

  def generate_script
    # Re-read the template
    self.class.load_templates if Rails.env.development?

    if options[:compress]
      uglifier.compress(render)
    else
      render
    end
  end

  def script_is_installed_properly
    return true if Rails.env.test?
    'HB.scriptIsInstalledProperly()'
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
      random_string << Digest::SHA1.hexdigest("#{ rand(1_000_000) }#{ site.url.to_s.upcase }#{ site.id }#{ Time.now.to_f }#{ rand(1_000_000) }")
      random_string
    end
  end

  def capabilities
    # TODO: This is temporary solution. We need to refactor capabilities injection:
    # 1) Get rid of no_b, b_variation, preview
    # 2) Don't use SiteSerializer here, the code should be moved to model
    {
      no_b: @site.capabilities.remove_branding? || @options[:preview],
      b_variation: branding_variation,
      preview: @options[:preview]
    }.merge(SiteSerializer.new(@site).capabilities)
  end

  def branding_variation
    # Options are ["original", "add_hb", "not_using_hb", "powered_by", "gethb", "animated"]
    'animated'
  end

  def capabilities_json
    capabilities.to_json
  end

  def content_upgrades_json
    site.site_elements.active_content_upgrades.inject({}) { |cu_json, cu|
      content = {
        id: cu.id,
        type: 'ContentUpgrade',
        offer_headline: cu.offer_headline.to_s.gsub('{{', '<a href="#">').gsub('}}', '</a>'),
        caption: cu.caption,
        headline: cu.headline,
        disclaimer: cu.disclaimer,
        link_text: cu.link_text,
        email_placeholder: cu.email_placeholder,
        name_placeholder: cu.name_placeholder,
        contact_list_id: cu.contact_list_id,
        download_link: cu.content_upgrade_download_link
      }
      cu_json.update cu.id => content
    }.to_json
  end

  def content_upgrades_styles_json
    site.content_upgrade_styles.to_json
  end

  def hb_backend_host
    Hellobar::Settings[:tracking_host]
  end

  def geolocation_url
    Hellobar::Settings[:geolocation_url]
  end

  def site_element_classes_js
    render_asset('site_elements.js')
  end

  def libs_js
    render_asset('libs.js')
  end

  def autofills_json
    site.autofills.to_json
  end

  def external_events_json
    external_events =
      site.site_elements.active.each_with_object([]) do |site_element, memo|
        site_element.external_events.each do |external_event|
          memo << external_event
        end
      end

    external_events.to_json
  end

  def modules_js
    render_asset('modules.js')
  end

  def core_js
    render_asset('core.js')
  end

  def hellobar_container_css
    css = [
      render_asset('container_common.css'),
      element_classes.map { |klass| render_asset(klass.name.downcase, 'container.css') },
      element_themes.map { |theme| render_asset(theme.container_css_path) }
    ]

    css.flatten.join("\n").gsub('hellobar-container', "#{ pro_secret }-container").to_json
  end

  def hellobar_element_css
    css = [
      render_asset('common.css'),
      element_classes.map { |klass| render_asset(klass.name.downcase, 'element.css') },
      element_themes.map { |theme| render_asset(theme.element_css_path) }
    ]

    css.flatten.join("\n").to_json
  end

  def branding_templates
    base = Rails.root.join('lib', 'script_generator')
    without_escaping_html_in_json do
      Dir.glob(base.join('branding', '*.html')).map do |f|
        path = Pathname.new(f)
        content = render_asset(path.relative_path_from(base)).to_json
        { name: path.basename.sub_ext('').to_s, markup: content }
      end
    end
  end

  def content_upgrade_template
    content = without_escaping_html_in_json { render_asset('contentupgrade/contentupgrade.html').to_json }
    [{ name: 'contentupgrade', markup: content }]
  end

  def templates
    template_names = Set.new

    if options[:templates]
      templates = Theme.where(type: 'template').collect(&:name)

      options[:templates].each do |t|
        temp_name = t.split('_', 2)
        category = :generic
        category = :template if templates.include?(temp_name[1].titleize)
        template_names << (temp_name << category)
      end
    else
      site.site_elements.active.each do |se|
        theme_id = se.theme_id
        theme = Theme.where(id: theme_id).first
        category = theme.type.to_sym
        subtype = (category == :template ? theme_id.underscore : se.element_subtype)

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
    rule.conditions.map { |c| condition_settings(c) }
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
    without_escaping_html_in_json do
      if category == :generic
        (content_header(element_class) +
          content_markup(element_class, type, category) +
          content_footer(element_class)).to_json
      else
        content_markup(element_class, type, category).to_json
      end
    end
  end

  def content_header(element_class)
    render_asset(element_class, 'header.html')
  end

  def content_markup(element_class, type, category = :generic)
    return '' if element_class == 'custom'

    if category == :generic
      render_asset(element_class, "#{ type.tr('/', '_').underscore }.html") do
        render_asset("#{ type.tr('/', '_').underscore }.html")
      end
    else
      path = [type.tr('_', '-')]

      render_asset(*path, "#{ element_class }.html") do
        render_asset(*path, 'element.html')
      end
    end
  end

  def content_footer(element_class)
    render_asset(element_class, 'footer.html')
  end

  def site_element_settings(site_element)
    settings = %w(
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
    )
    settings << 'caption' unless site_element.use_question?

    lifetime_totals = @site.lifetime_totals
    conversion_data = lifetime_totals ? lifetime_totals[site_element.id.to_s] : nil
    views = conversions = conversion_rate = 0

    if conversion_data && conversion_data[0]
      views = conversion_data[0][0]
      conversions = conversion_data[0][1]
      if views > 0
        conversion_rate = ((conversions.to_f / views) * 1000).floor.to_f / 1000
      end
    end

    site_element.attributes.select { |key, _| settings.include?(key) }.merge(
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
      branding_url: "http://www.hellobar.com?sid=#{ site_element.id }",
      closable: site_element.is_a?(Bar) || site_element.is_a?(Slider) ? site_element.closable : false,
      contact_list_id: site_element.contact_list_id,
      conversion_rate: conversion_rate,
      conversions: conversions,
      custom_html: site_element.custom_html,
      custom_css: site_element.custom_css,
      custom_js: site_element.custom_js,
      email_redirect: site_element.email_redirect?,
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
      template_name: "#{ site_element.class.name.downcase }_#{ site_element.element_subtype }",
      thank_you_text: SiteElement.sanitize(site_element.display_thank_you_text).gsub(/"/, '&quot;'),
      views: views,
      updated_at: site_element.updated_at.to_f * 1000,
      use_free_email_default_msg: site_element.show_default_email_message? && site_element.site.free?,
      wiggle_wait: 0,
      blocks: site_element.blocks,
      theme: site_element.theme.attributes
    ).select { |_, value| !value.nil? }
  end

  def site_elements_for_rule(rule, hashify = true)
    site_elements =
      if options[:bar_id]
        [rule.site_elements.find(options[:bar_id])]
      elsif options[:render_paused_site_elements]
        rule.site_elements
      else
        rule.site_elements.active
      end

    hashify ? site_elements.map { |element| site_element_settings(element) } : site_elements
  end

  def all_site_elements
    site.rules.map { |rule| site_elements_for_rule(rule, false) }.flatten
  end

  def element_classes
    @options[:preview] ? SiteElement::TYPES : all_site_elements.map(&:class).uniq
  end

  def element_themes
    @options[:preview] ? Theme.all : all_site_elements.map(&:theme).compact.uniq
  end

  # try to render asset from app's assets
  # if an asset is not found either
  # calls given block or raises StandardError
  def render_asset(*path)
    file = File.join(*path)
    asset = asset(file)
    return asset.toutf8 if asset
    return yield if block_given?
    raise Sprockets::FileNotFound, "couldn't find file '#{ file }'"
  rescue Sass::SyntaxError => e
    e.sass_template ||= path.join('/')
    raise e
  end

  def without_escaping_html_in_json
    ActiveSupport.escape_html_entities_in_json = false
    result = yield
    ActiveSupport.escape_html_entities_in_json = true
    result
  end

  def asset(file)
    manifest.find_sources(file).first
  rescue TypeError
    nil
  end

  def manifest(fresh = false)
    @manifest ||= self.class.manifest(fresh || options[:preview])
  end
end
