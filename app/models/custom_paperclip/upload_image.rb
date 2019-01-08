class CustomPaperclip::UploadImage
  extend ActiveModel::Naming
  extend ActiveModel::Callbacks
  include ActiveModel::Validations
  include ActiveModel::Model
  include Paperclip::Glue

  # Paperclip required callbacks
  define_model_callbacks :save, only: [:after]
  define_model_callbacks :commit, only: [:after]
  define_model_callbacks :destroy, only: %i[before after]

  ALLOWED_SIZE_RANGE = 1..1500.kilobytes.freeze
  ALLOWED_CONTENT = ['image/jpeg', 'image/gif', 'image/png'].freeze

  attr_accessor :photo_file_name, :photo_content_type, :photo_file_size, :photo_updated_at, :id

  has_attached_file :photo, bucket: Settings.s3_campaign_bucket,
                    s3_region: Settings.aws_region,
                    storage: :s3,
                    path: 'emails/:folder_name/:id/:filename'

  do_not_validate_attachment_file_type :photo

  # validates_attachment :photo, presence: true, content_type: { content_type: ALLOWED_CONTENT }, size: { in: ALLOWED_SIZE_RANGE }

  def save
    return false if photo.blank?
    run_callbacks :save do
      self.id = Time.current.to_i
    end
    true
  end

  Paperclip.interpolates :folder_name do
    Date.current.strftime('%m-%d-%y')
  end

  def to_model
    self
  end

  def valid?
    true
  end

  def new_record?
    true
  end

  def destroyed?
    true
  end

  def destroy
    run_callbacks :destroy
  end

  def updated_at_short
    Time.current.to_s(:autosave_time)
  end

  def errors
    obj = Object.new

    def obj.[](*)
      []
    end

    def obj.full_messages
      []
    end

    def obj.any?
      false
    end

    obj
  end
end
