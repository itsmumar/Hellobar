class ImageUpload < ActiveRecord::Base
  belongs_to :site

  has_attached_file :image, styles: { original: '600x360>', thumb: '100x100>' }
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
  after_validation :better_error_messages, on: [:create]

  def better_error_messages
    if errors[:image].include?('Paperclip::Errors::NotIdentifiedByImageMagickError')
      errors.delete(:image)
      errors[:image] = 'Invalid image file.'
    end
  end

  def url
    preuploaded_url || image.url
  end
end
