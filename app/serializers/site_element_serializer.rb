class SiteElementSerializer < ActiveModel::Serializer
  attributes :id, :site, :rule_id, :rule, :contact_list_id, :paused_at,
    #
    # settings
    :type, :element_subtype, :settings, :view_condition, :phone_number,
    :phone_country_code, :email_redirect, :enable_gdpr,
    #
    # text
    :headline, :caption, :content, :link_text, :font_id, :thank_you_text, :email_placeholder, :name_placeholder,
    :preset_rule_name, :show_optional_content, :show_optional_caption, :show_thankyou,
    #
    # colors
    :background_color, :border_color, :button_color, :link_color, :text_color, :cross_color,
    #
    # style
    :closable, :show_branding, :pushes_page_down, :remains_at_top,
    :animated, :wiggle_button, :theme, :theme_id,
    :cta_border_color, :cta_border_width, :cta_border_radius, :cta_height,
    #
    # image
    :image_url, :image_large_url, :image_modal_url, :image_style,
    :image_placement, :active_image_id, :image_file_name, :use_default_image,
    :image_opacity, :image_overlay_color, :image_overlay_opacity,
    #
    # questions/answers/responses
    :question, :answer1, :answer2, :answer1response, :answer2response, :answer1caption, :answer2caption, :answer1link_text, :answer2link_text, :use_question,
    :question_placeholder, :answer1_placeholder, :answer2_placeholder, :answer1response_placeholder, :answer2response_placeholder, :answer1link_text_placeholder, :answer2link_text_placeholder,
    #
    # alert type
    :trigger_color, :trigger_icon_color, :notification_delay, :sound,
    #
    # text field styling
    :text_field_border_color, :text_field_border_width, :text_field_border_radius,
    :text_field_text_color, :text_field_background_color, :text_field_background_opacity, :text_field_font_size, :text_field_font_family,
    #
    # other
    :updated_at, :size, :site_preview_image, :site_preview_image_mobile,
    :site_preview_image_tablet, :required_fields,
    :open_in_new_window, :placement, :default_email_thank_you_text,
    #
    # no-thanks
    :show_no_thanks, :no_thanks_text,
    # conversion
    :conversion_font, :conversion_font_color, :conversion_font_size, :conversion_cta_text, :edit_conversion_cta_text

  SiteElement::QUESTION_DEFAULTS.each_key do |attr_name|
    define_method "#{ attr_name }_placeholder" do
      SiteElement::QUESTION_DEFAULTS[attr_name]
    end
  end

  def email_redirect
    object.email_redirect?
  end

  def caption
    # Questions use their own captions.
    object.caption.presence unless object.use_question?
  end

  def rule
    return unless object.rule

    RuleSerializer.new(object.rule).as_json
  end

  def preset_rule_name
    return '' unless object.rule

    if object.rule.editable
      'Saved'
    else
      object.rule.name
    end
  end

  def size
    return 0 if object.size.blank?

    case object.size
    when 'large'
      50
    when 'regular'
      30
    else
      object.size.to_i
    end
  end

  def site
    return unless object.site

    SiteSerializer.new(object.site, scope: scope).as_json
  end

  def theme
    return unless object.theme

    ThemeSerializer.new(object.theme, scope: scope).as_json
  end

  def theme_id
    object.theme.try(:id)
  end

  def site_preview_image
    return '' unless object.site
    proxied_url2png(url: object.site.url)
  end

  def site_preview_image_mobile
    return '' unless object.site
    proxied_url2png(url: object.site.url, viewport: '375x667')
  end

  def site_preview_image_tablet
    return '' unless object.site
    proxied_url2png(url: object.site.url, viewport: '768x1024')
  end

  def proxied_url2png(options)
    '/proxy/https/' + Url2png.new(options).call
  end
end
