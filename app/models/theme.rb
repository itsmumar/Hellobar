class Theme < ActiveHash::Base
  include ActiveModel::Serialization

  CONTAINER_CSS_FILENAME = 'container'.freeze
  ELEMENT_CSS_FILENAME   = 'element'.freeze

  def container_css_path
    base_directory.join("#{ CONTAINER_CSS_FILENAME }.css").to_s
  end

  def element_css_path
    base_directory.join("#{ ELEMENT_CSS_FILENAME }.css").to_s
  end

  def with_image?
    image['default_url'].present?
  end

  def self.sorted
    all.sort_by { |t| [t.default_theme ? 0 : 1, t.name] }
  end

  private

  def base_directory
    Pathname.new(directory).split.last
  end
end
