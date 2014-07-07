class SiteElementSerializer < ActiveModel::Serializer
  attributes :id,

    # settings
    :element_subtype, :link_url,

    # text
    :message, :link_text, :font,

    # colors
    :background_color, :border_color, :button_color, :link_color, :text_color

  def link_url
    object.settings["url"]
  end
end
