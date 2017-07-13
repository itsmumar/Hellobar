class ThemeSerializer < ActiveModel::Serializer
  attributes :id, :type, :name, :element_types, :defaults, :fonts, :image, :disabled
end
