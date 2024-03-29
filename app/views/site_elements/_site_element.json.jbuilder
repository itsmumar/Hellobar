json.ignore_nil!
json.cache! site_element do
  json.extract! site_element,
    :id,
    :answer1,
    :answer1response,
    :answer1caption,
    :answer1link_text,
    :answer2,
    :answer2response,
    :answer2caption,
    :answer2link_text,
    :answer2url,
    :answer1url,
    :use_redirect_url,
    :use_question,
    :question,
    :contact_list_id,
    :use_default_image,
    :image_url,
    :image_large_url,
    :image_modal_url,
    :image_style,
    :image_opacity,
    :image_overlay_color,
    :image_overlay_opacity,
    :open_in_new_window,
    :phone_number,
    :primary_color,
    :pushes_page_down,
    :remains_at_top,
    :secondary_color,
    :settings,
    :animated,
    :background_color,
    :border_color,
    :button_color,
    :email_placeholder,
    :headline,
    :content,
    :show_optional_content,
    :show_optional_caption,
    :image_placement,
    :link_color,
    :link_text,
    :name_placeholder,
    :phone_number,
    :placement,
    :show_border,
    :show_branding,
    :size,
    :text_color,
    :theme_id,
    :type,
    :view_condition,
    :wiggle_button,
    :wordpress_bar_id,
    :fonts,
    :required_fields,
    :text_field_border_color,
    :text_field_border_width,
    :text_field_font_size,
    :text_field_font_family,
    :text_field_border_radius,
    :text_field_text_color,
    :text_field_background_color,
    :text_field_background_opacity,
    :show_thankyou,
    :conversion_font,
    :conversion_font_color,
    :conversion_font_size,
    :conversion_cta_text,
    :edit_conversion_cta_text,
    :show_no_thanks,
    :no_thanks_text,
    # alert bar
    :sound,
    :notification_delay,
    :trigger_color,
    :trigger_icon_color,
    :enable_gdpr,
    :cta_border_color,
    :cta_border_width,
    :cta_border_radius,
    :cross_color,
    :cta_height

  json.font site_element.font.try(:value)

  json.theme do
    json.image do
      json.default_url site_element.theme.image['default_url']
      json.position_default site_element.theme.image['position_default']
    end
  end

  json.google_font site_element.font.try(:google_font)
  json.subtype site_element.short_subtype
  json.wiggle_wait 0
  json.email_redirect site_element.email_redirect?

  json.thank_you_text site_element.display_thank_you_text.gsub(/"/, '&quot;')

  json.template_name "#{ site_element.class.name.downcase }_#{ site_element.element_subtype }"

  json.branding_url "#{ Settings.marketing_site_url }?sid=#{ site_element.id }"

  json.closable(site_element.is_a?(Bar) || site_element.is_a?(Slider) ? site_element.closable : false)

  json.use_free_email_default_msg site_element.show_default_email_message? && site_element.site.free?

  json.updated_at site_element.updated_at.to_f * 1000

  json.caption site_element.caption unless site_element.use_question?

  statistics = site_element.statistics
  json.views statistics.views
  json.conversion_rate statistics.conversion_rate
end
