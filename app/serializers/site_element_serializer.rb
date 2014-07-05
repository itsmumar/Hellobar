class SiteElementSerializer < ActiveModel::Serializer
  attributes :id,

    # settings
    :element_subtype,

    # text
    :message, :link_text, :font
end
