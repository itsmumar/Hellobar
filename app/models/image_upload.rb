require 'set'

class ImageUpload < ActiveRecord::Base
  DEFAULT_STYLE = :original
  DEFAULT_VERSION = 1

  VERSION_STYLES = {
    1 => Set[:original, :thumb].freeze,
    2 => Set[:original, :thumb, :small, :medium, :large, :modal].freeze
  }.freeze

  STYLES = {
    original: '2000x2000>',
    thumb: '100x100>',
    small: '500x500>',
    medium: '1000x1000>',
    large: '1500x1500>',
    modal: '600x360>' # for legacy purposes
  }.freeze

  belongs_to :site

  has_attached_file :image, styles: STYLES
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
  after_validation :better_error_messages, on: [:create]

  validates :version, presence: true, inclusion: { in: VERSION_STYLES.keys }

  def better_error_messages
    return unless errors[:image].include?('Paperclip::Errors::NotIdentifiedByImageMagickError')

    errors.delete(:image)
    errors[:image] = 'Invalid image file.'
  end

  def url(style = :modal)
    style = safe_style(style)

    preuploaded_url || image.url(style)
  end

  def modal_url
    url(:modal)
  end

  def thumb_url
    url(:thumb)
  end

  def small_url
    url(:small)
  end

  def medium_url
    url(:medium)
  end

  def large_url
    url(:large)
  end

  def original_url
    url(:original)
  end

  private

  def safe_style(style)
    style = DEFAULT_STYLE unless styles.include?(style)

    style
  end

  def styles
    VERSION_STYLES[version] || VERSION_STYLES[DEFAULT_VERSION]
  end
end
