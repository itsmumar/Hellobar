class StaticScriptModel
  include ActiveModel::Conversion

  attr_reader :site, :options

  delegate :id, :url, :write_key, :rules, to: :site, prefix: true
  delegate :autofills, :cache_key, :persisted?, to: :site

  def initialize(site, options = {})
    @site = site
    @options = options
  end

  def to_json
    StaticScriptAssets.render_model(self)
  end

  def preview_is_active
    preview?
  end

  def version
    GitUtils.current_commit
  end

  def timestamp
    Time.current
  end

  def capabilities
    {
      no_b: site.capabilities.remove_branding? || preview?,
      b_variation: branding_variation,
      preview: preview?
    }.merge(SiteSerializer.new(site).capabilities)
  end

  def pro_secret
    @pro_secret ||=
      begin
        ('a'..'z').to_a.sample +
          Digest::SHA1.hexdigest("#{ rand(1_000_000) }#{ site.url.to_s.upcase }#{ site.id }#{ Time.current.to_f }#{ rand(1_000_000) }")
      end
  end

  def site_timezone
    return if site.timezone.blank?
    Time.find_zone!(site.timezone).formatted_offset
  end

  def hellobar_container_css
    css = [
      render_asset('container_common.css'),
      element_types.map { |type| render_asset(type.downcase, 'container.css') },
      element_themes.map { |theme| render_asset(theme.container_css_path) }
    ]

    css.flatten.join("\n").gsub('hellobar-container', "#{ pro_secret }-container")
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
      site.active_site_elements.each do |se|
        category = se.theme.type.to_sym
        subtype = (category == :template ? se.theme_id.underscore : se.element_subtype)

        bar_type = se.class.name.downcase
        template_names << [bar_type, subtype, category]
        template_names << [bar_type, 'question', category] if se.use_question?
      end
    end

    template_names.map do |name|
      {
        name: name.first(2).join('_'),
        markup: content_template(name[0], name[1], name[2])
      }
    end
  end

  def branding_templates
    base = Rails.root.join('lib', 'script_generator')

    Dir.glob(base.join('branding', '*.html')).map { |f| Pathname.new(f) }.map do |path|
      content = render_asset(path.relative_path_from(base))
      { name: 'branding_' + path.basename.sub_ext('').to_s, markup: content }
    end
  end

  def content_upgrade_template
    [{ name: 'contentupgrade', markup: render_asset('contentupgrade/contentupgrade.html') }]
  end

  def geolocation_url
    Settings.geolocation_url
  end

  def hb_backend_host
    URI.parse(Settings.tracking_api_url).host
  end

  def external_tracking
    return [] unless site && site.capabilities.external_tracking?

    site.active_site_elements.flat_map(&method(:external_tracking_for)) +
      site.site_elements.active_content_upgrades.flat_map(&method(:external_tracking_for))
  end

  def rules
    return [] if options[:no_rules]
    site_rules.map { |rule| hash_for_rule(rule) }
  end

  def hellobar_element_css
    css = [
      render_asset('common.css'),
      element_types.map { |type| render_asset(type.downcase, 'element.css') },
      element_themes.map { |theme| render_asset(theme.element_css_path) }
    ]

    css.flatten.join("\n")
  end

  def content_upgrades
    site.site_elements.active_content_upgrades.map { |content_upgrade|
      {
        content_upgrade.id => {
          id: content_upgrade.id,
          type: content_upgrade.type,
          offer_headline: content_upgrade.offer_headline.to_s.gsub('{{', '<a href="#">').gsub('}}', '</a>'),
          caption: content_upgrade.caption,
          headline: content_upgrade.headline,
          disclaimer: content_upgrade.disclaimer,
          link_text: content_upgrade.link_text,
          thank_you_enabled: content_upgrade.thank_you_enabled,
          thank_you_headline: content_upgrade.thank_you_headline,
          thank_you_subheading: content_upgrade.thank_you_subheading,
          thank_you_cta: content_upgrade.thank_you_cta,
          thank_you_url: content_upgrade.thank_you_url,
          email_placeholder: content_upgrade.email_placeholder,
          name_placeholder: content_upgrade.name_placeholder,
          contact_list_id: content_upgrade.contact_list_id,
          download_link: content_upgrade.content_upgrade_download_link,
          subtype: content_upgrade.short_subtype
        }
      }
    }.inject({}, &:update)
  end

  def content_upgrades_styles
    site.content_upgrade_styles
  end

  def script_is_installed_properly
    Rails.env.test? || 'scriptIsInstalledProperly()'
  end

  private

  # Hardcoded array of external events for Google Analytics
  # In the future we will consider providing a customizable UI for this
  def external_tracking_for(element)
    providers = ['google_analytics', 'legacy_google_analytics']
    default = Hash[site_element_id: element.id, category: 'Hello Bar', label: "#{ element.class.name }-#{ element.id }"]

    providers.each_with_object([]) do |provider, memo|
      memo << default.merge(provider: provider, type: 'view', action: 'View')
      memo << default.merge(provider: provider, type: "#{ element.short_subtype }_conversion", action: 'Conversion')
    end
  end

  def branding_variation
    # Options are ["original", "add_hb", "not_using_hb", "powered_by", "gethb", "animated"]
    'animated'
  end

  def preview?
    options[:preview].present?
  end

  def element_types
    preview? ? SiteElement.types : all_site_elements.map(&:class).map(&:name).uniq
  end

  def element_themes
    preview? ? Theme.all : all_site_elements.map(&:theme).compact.uniq
  end

  def all_site_elements
    site_rules.flat_map(&:active_site_elements)
  end

  def content_template(bar_type, type, category = :generic)
    if category == :generic
      content_header(bar_type) +
        content_markup(bar_type, type, category) +
        content_footer(bar_type)
    else
      content_markup(bar_type, type, category)
    end
  end

  def content_header(bar_type)
    render_asset(bar_type, 'header.html')
  end

  def content_markup(bar_type, subtype, category = :generic)
    return '' if bar_type == 'custom'

    if category == :generic
      path = subtype.tr('/', '_')
      render_asset("#{ path }.html")
    else
      path = subtype.tr('_', '-')
      render_asset(path, "#{ bar_type }.html")
    end
  end

  def content_footer(bar_type)
    render_asset(bar_type, 'footer.html')
  end

  def hash_for_rule(rule)
    {
      match: rule.match,
      conditions: conditions_for_rule(rule),
      site_elements: rule.active_site_elements
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

  def render_asset(*path)
    StaticScriptAssets.render(*path, site_id: site_id)
  end
end
