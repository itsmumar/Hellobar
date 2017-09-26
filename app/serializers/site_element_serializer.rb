class SiteElementSerializer < ActiveModel::Serializer
  attributes :id, :site, :rule_id, :rule, :contact_list_id,

    # settings
    :type, :element_subtype, :settings, :view_condition, :phone_number,
    :phone_country_code, :blocks, :email_redirect,

    # text
    :headline, :caption, :content, :link_text, :font_id, :thank_you_text, :email_placeholder, :name_placeholder,
    :preset_rule_name, :disclaimer, :offer_text, :offer_headline,

    # colors
    :background_color, :border_color, :button_color, :link_color, :text_color,

    # style
    :closable, :show_branding, :pushes_page_down, :remains_at_top,
    :animated, :wiggle_button, :theme, :theme_id,

    # image
    :image_url, :image_large_url, :image_modal_url, :image_style,
    :image_placement, :active_image_id, :image_file_name, :use_default_image,
    :image_opacity,

    # questions/answers/responses
    :question, :answer1, :answer2, :answer1response, :answer2response, :answer1caption, :answer2caption, :answer1link_text, :answer2link_text, :use_question,
    :question_placeholder, :answer1_placeholder, :answer2_placeholder, :answer1response_placeholder, :answer2response_placeholder, :answer1link_text_placeholder, :answer2link_text_placeholder,

    # alert type
    :trigger_color, :trigger_icon_color, :notification_delay, :sound,

    # other
    :updated_at, :link_style, :size, :site_preview_image, :site_preview_image_mobile,
    :open_in_new_window, :placement, :default_email_thank_you_text

  SiteElement::QUESTION_DEFAULTS.keys.each do |attr_name|
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
    RuleSerializer.new(object.rule)
  end

  def preset_rule_name
    return '' unless object.rule

    if rule.editable
      'Saved'
    else
      rule.name
    end
  end

  def site
    SiteSerializer.new(object.site, scope: scope)
  end

  def theme
    ThemeSerializer.new(object.theme, scope: scope)
  end

  def theme_id
    object.theme.try(:id)
  end

  def site_preview_image
    object.site ? proxied_url2png("?url=#{ ERB::Util.url_encode(object.site.url) }") : ''
  end

  def site_preview_image_mobile
    object.site ? proxied_url2png("?url=#{ ERB::Util.url_encode(object.site.url) }&viewport=320x568") : ''
  end

  def proxied_url2png(params)
    '/proxy/https/' + url2png(params).sub(/^https:\/\//, '')
  end

  def url2png(params)
    css_url = "http://#{ Settings.host }/stylesheets/hide_bar.css"
    # Include CSS to hide any Hello Bar already there
    params += "&custom_css_url=#{ ERB::Util.url_encode(css_url) }"
    # Cache for 7 days
    params += "&ttl=#{ 7 * 24 * 60 * 60 }"
    # Calculate the token
    token = Digest::MD5.hexdigest("#{ params }SC10DF8C7E0FE8")
    "https://api.url2png.com/v6/P52EBC321291EF/#{ token }/png/#{ params }"
  end
end
