class Theme < ActiveHash::Base
  include ActiveModel::Serialization

  def container_css_path
    base_directory.join('container.css').to_s
  end

  def element_css_path
    base_directory.join('element.css').to_s
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
