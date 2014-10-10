class SiteElementSerializer < ActiveModel::Serializer
  attributes :id, :site, :rule_id, :rule, :contact_list_id, :errors, :full_error_messages,

    # settings
    :element_subtype, :settings, :display_when,

    # text
    :message, :link_text, :font,

    # colors
    :background_color, :border_color, :button_color, :link_color, :text_color,

    # style
    :closable, :show_branding,

    # other
    :link_style, :size, :site_preview_image, :site_preview_image_mobile

  def rule
    RuleSerializer.new(object.rule)
  end

  def site
    SiteSerializer.new(object.site)
  end

  def site_preview_image
    object.site ? url2png("?url=#{object.site.url}") : ""
  end

  def site_preview_image_mobile
    object.site ? url2png("?url=#{object.site.url}&viewport=320x568") : ""
  end

  def url2png(params)
    css_url = "http://#{Hellobar::Settings[:host]}/stylesheets/hide_bar.css"
    params += "&custom_css_url=#{css_url}"
    token = Digest::MD5.hexdigest("#{params}SC10DF8C7E0FE8")
    "https://api.url2png.com/v6/P52EBC321291EF/#{token}/png/#{params}"
  end

  def errors
    object.errors.to_hash
  end

  def full_error_messages
    messages = []

    object.errors.keys.each do |attribute|
      errors = object.errors[attribute]

      if attribute == :element_subtype && errors.include?("can't be blank")
        messages << "You must select a type in the \"settings\" section"
        next
      end

      if attribute == :rule && errors.include?("can't be blank")
        messages << "You must select who will see this in the \"targeting\" section"
        next
      end

      if attribute == :contact_list && errors.include?("can't be blank")
        messages << "You must select a contact list to sync with in the \"settings\" section"
        next
      end

      errors.each do |error|
        messages << object.errors.full_message(attribute, error)
      end
    end

    messages
  end
end
