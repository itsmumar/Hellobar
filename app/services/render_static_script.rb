require 'digest/sha1'
require 'hmac-sha1'
require 'hmac-sha2'

class RenderStaticScript < Mustache
  self.raise_on_context_miss = true

  def self.load_templates
    self.template_path = Rails.root.join('lib', 'script_generator')
    self.template_name = 'template.js'
  end
  load_templates

  attr_reader :site, :options, :manifest, :timestamp, :version
  delegate :id, :url, :write_key, to: :site, prefix: true

  def initialize(site, options = {})
    @site = site
    @options = options
  end

  def call
    # Re-read the template
    self.class.load_templates if Rails.env.development?
    initialize_version_and_timestamp

    if options[:compress]
      StaticScriptAssets.compress(render)
    else
      render
    end
  rescue => e
    Rails.logger.error e
    raise e
  end

  def script_is_installed_properly
    return true if Rails.env.test?
    'scriptIsInstalledProperly()'
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
      random_string << Digest::SHA1.hexdigest("#{ rand(1_000_000) }#{ site.url.to_s.upcase }#{ site.id }#{ Time.current.to_f }#{ rand(1_000_000) }")
      random_string
    end
  end

  def capabilities
    # TODO: This is temporary solution. We need to refactor capabilities injection:
    # 1) Get rid of no_b, b_variation, preview
    # 2) Don't use SiteSerializer here, the code should be moved to model
    {
      no_b: site.capabilities.remove_branding? || @options[:preview],
      b_variation: branding_variation,
      preview: @options[:preview]
    }.merge(SiteSerializer.new(@site).capabilities)
  end

  def branding_variation
    # Options are ["original", "add_hb", "not_using_hb", "powered_by", "gethb", "animated"]
    'animated'
  end

  def preview_is_active
    @options[:preview]
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

  def autofills_json
    site.autofills.to_json
  end

  def external_tracking_json
    site.active_site_elements.map(&:external_tracking).flatten.to_json
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
        { name: 'branding_' + path.basename.sub_ext('').to_s, markup: content }
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
    options[:rules] || site_rules.map { |rule| hash_for_rule(rule) }
  end

  private

  def hash_for_rule(rule)
    {
      match: rule.match,
      conditions: conditions_for_rule(rule).to_json,
      site_elements: render_site_elements(site_elements_for_rule(rule))
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
      render_asset("#{ type.tr('/', '_').underscore }.html")
    else
      path = [type.tr('_', '-')]

      render_asset(*path, "#{ element_class }.html")
    end
  end

  def content_footer(element_class)
    render_asset(element_class, 'footer.html')
  end

  def render_site_elements(site_elements)
    StaticScriptAssets.render_json('site_elements/site_elements', site_elements: site_elements).gsub('</script>', '<\/script>')
  end

  def site_elements_for_rule(rule)
    if options[:bar_id]
      [rule.site_elements.find(options[:bar_id])]
    elsif options[:render_paused_site_elements]
      rule.site_elements
    else
      rule.active_site_elements
    end
  end

  def all_site_elements
    site_rules.map { |rule| site_elements_for_rule(rule) }.flatten
  end

  def element_classes
    @options[:preview] ? SiteElement::TYPES : all_site_elements.map(&:class).uniq
  end

  def element_themes
    @options[:preview] ? Theme.all : all_site_elements.map(&:theme).compact.uniq
  end

  def site_rules
    @site_rules ||= site.rules
  end

  def render_asset(*path)
    StaticScriptAssets.render(*path, site_id: site_id)
  end

  def without_escaping_html_in_json
    ActiveSupport.escape_html_entities_in_json = false
    yield
  ensure
    ActiveSupport.escape_html_entities_in_json = true
  end

  def initialize_version_and_timestamp
    @timestamp = Time.current
    @version = GitUtils.current_commit
  end
end
