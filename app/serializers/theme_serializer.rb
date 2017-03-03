class ThemeSerializer < ActiveModel::Serializer
  attributes :id, :type, :name, :element_types, :defaults, :fonts, :image, :image_upload_id

  def image_upload_id
    ImageUpload.find_by(theme_id: object.id).try(:id)
  end
end
