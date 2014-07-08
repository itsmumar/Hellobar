class SiteElementSerializer < ActiveModel::Serializer
  attributes :id,

    # settings
    :element_subtype, :settings,

    # text
    :message, :link_text, :font,

    # colors
    :background_color, :border_color, :button_color, :link_color, :text_color
end
