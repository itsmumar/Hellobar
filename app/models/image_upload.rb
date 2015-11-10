class ImageUpload < ActiveRecord::Base
  belongs_to :site

  has_attached_file :image, styles: { original: "600x360>", thumb: "100x100>" }
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

  delegate :url, to: :image
end
