class ImageUpload < ApplicationRecord
  STYLES = {
    original: '2000x2000>',
    large: '1500x1500>',
    modal: '600x360>' # for legacy purposes
  }.freeze

  belongs_to :site
  has_many :site_elements, foreign_key: :active_image_id, dependent: :nullify,
    inverse_of: :active_image

  has_attached_file :image, styles: STYLES
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
  after_validation :better_error_messages, on: [:create]

  def better_error_messages
    return unless errors[:image].include?('Paperclip::Errors::NotIdentifiedByImageMagickError')

    errors.delete(:image)
    errors[:image] = 'Invalid image file.'
  end

  def url(style = :modal)
    image.url(style)
  end

  STYLES.each_key do |style|
    define_method "#{ style }_url" do
      url(style)
    end
  end
end
