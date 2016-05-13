class ThemeSerializer < ActiveModel::Serializer
  attributes :id, :name, :defaults, :fonts
end
