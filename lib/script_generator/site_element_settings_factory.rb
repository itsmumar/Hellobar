class ScriptGenerator
  class SiteElementSettingsFactory
    def self.make(site_element)
      new(site_element).make
    end

    attr_reader :site_element

    def initialize(site_element)
      @site_element = site_element
    end

    def make
      site_element
        .attributes
        .slice(*attributes)
        .merge(settings)
        .merge(conversion)
        .select { |_, value| !value.nil? }
    end

    def settings
      {
        font: site_element.font.value,
        google_font: site_element.font.google_font,
        branding_url: "http://www.hellobar.com?sid=#{ site_element.id }",
        closable: site_element.is_a?(Bar) || site_element.is_a?(Slider) ? site_element.closable : false,
        email_redirect: site_element.email_redirect?,
        hide_destination: true,
        tab_side: 'right',
        target: site_element.target_segment,
        template_name: "#{ site_element.class.name.downcase }_#{ site_element.element_subtype }",
        thank_you_text: SiteElement.sanitize(site_element.display_thank_you_text).gsub(/"/, '&quot;'),
        updated_at: site_element.updated_at.to_f * 1000,
        use_free_email_default_msg: site_element.show_default_email_message? && site_element.site.free?,
        wiggle_wait: 0,
        subtype: site_element.short_subtype,
        theme: site_element.theme.attributes,
        primary_color: site_element.primary_color,
        secondary_color: site_element.secondary_color
      }
    end

    def attributes
      %w(
        animated background_color border_color button_color email_placeholder headline
        image_placement link_color link_style link_text name_placeholder phone_number
        placement show_border show_branding size target text_color texture theme_id
        type view_condition wiggle_button wordpress_bar_id blocks
        answer1 answer1response answer1caption answer1link_text answer2 answer2response answer2caption
        answer2link_text use_question question
        contact_list_id custom_html custom_css custom_js
        image_url open_in_new_window phone_number
        remains_at_top pushes_page_down settings blocks id
      ).tap do |attrs|
        attrs << 'caption' unless site_element.use_question?
      end
    end

    def conversion
      lifetime_totals = site_element.site.lifetime_totals
      conversion_data = lifetime_totals ? lifetime_totals[site_element.id.to_s] : nil
      views = conversions = conversion_rate = 0

      if conversion_data && conversion_data[0]
        views = conversion_data[0][0]
        conversions = conversion_data[0][1]
        if views > 0
          conversion_rate = ((conversions.to_f / views) * 1000).floor.to_f / 1000
        end
      end

      {
        views: views,
        conversions: conversions,
        conversion_rate: conversion_rate
      }
    end
  end
end
