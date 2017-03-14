class Theme < ActiveHash::Base
  include ActiveModel::Serialization

  CONTAINER_CSS_FILENAME = 'container'
  ELEMENT_CSS_FILENAME   = 'element'

  def container_css_path
    Pathname.new(directory).split.last.join("#{ CONTAINER_CSS_FILENAME }.css").to_s
  end

  def element_css_path
    Pathname.new(directory).split.last.join("#{ ELEMENT_CSS_FILENAME }.css").to_s
  end

  def with_image?
    image['default_url'].present?
  end

  def self.sorted
    all.sort_by { |t| [t.default_theme ? 0 : 1, t.name] }
  end
end
