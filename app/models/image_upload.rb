class ImageUpload < ActiveRecord::Base
  DEFAULT_STYLE = :original
  DEFAULT_VERSION = 1

  VERSION_STYLES = {
    1 => Set[DEFAULT_STYLE, :thumb].freeze,
    2 => Set[DEFAULT_STYLE, :thumb, :small, :medium, :large, :modal].freeze
  }.freeze

  STYLES = {
    DEFAULT_STYLE => '2000x2000>',
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
    preuploaded_url || image.url(safe_style(style))
  end

  STYLES.keys.each do |style|
    define_method "#{ style }_url" do
      url(style)
    end
  end

  private

  def safe_style(style)
    styles.include?(style) ? style : DEFAULT_STYLE
  end

  def styles
    VERSION_STYLES[version] || VERSION_STYLES[DEFAULT_VERSION]
  end
end
