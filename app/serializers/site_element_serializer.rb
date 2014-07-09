class SiteElementSerializer < ActiveModel::Serializer
  attributes :id, :site, :rule_id,

    # settings
    :element_subtype, :settings,

    # text
    :message, :link_text, :font,

    # colors
    :background_color, :border_color, :button_color, :link_color, :text_color

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
end
