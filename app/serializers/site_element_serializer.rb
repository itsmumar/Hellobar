class SiteElementSerializer < ActiveModel::Serializer
  attributes :id,

    # settings
    :element_subtype, :link_url,

    # text
    :message, :link_text, :font

  def link_url
    object.settings["url"]
  end
end
