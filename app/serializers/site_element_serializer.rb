class SiteElementSerializer < ActiveModel::Serializer
  attributes :id, :site, :rule_id,

    # settings
    :element_subtype, :settings,

    # text
    :message, :link_text, :font,

    # colors
    :background_color, :border_color, :button_color, :link_color, :text_color,

    # other
    :link_style, :size, :site_preview_image

  def site
    {
      :id => object.site.id,
      :url => object.site.url,
      :rules => object.site.rules.map do |rule|
        {
          :id => rule.id,
          :name => rule.name.blank? ? "rule ##{rule.id}" : rule.name,
          :conditions => rule.to_sentence
        }
      end
    }
  end

  def site_preview_image
    params = "?url=#{object.site.url}"
    token = Digest::MD5.hexdigest("#{params}SC10DF8C7E0FE8")
    "https://api.url2png.com/v6/P52EBC321291EF/#{token}/png/#{params}"
  end
end
