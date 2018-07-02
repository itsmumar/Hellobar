class ContactList < ApplicationRecord
  acts_as_paranoid

  belongs_to :site
  belongs_to :identity, dependent: :destroy

  has_many :site_elements, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :sequences, dependent: :destroy

  store :data, coder: Hash

  before_validation :reject_empty_data_values, :clean_embed_code
  after_destroy :nullify_identity_reference

  validates :name, presence: true
  validates :site, presence: true, associated: true
  validate :provider_valid, if: :provider_set?
  validate :provider_credentials_exist, if: :provider_set?
  validate :embed_code_exists?, if: :embed_code?
  validate :embed_code_valid?, if: :embed_code?
  validate :webhook_url_valid?, if: -> { webhook? || zapier? }

  delegate :count, to: :site_elements, prefix: true

  attr_accessor :provider_token

  def provider_name
    identity&.provider_name || 'Hello Bar'
  end

  def provider_icon_path
    identity&.provider_icon_path || 'providers/hellobar.png'
  end

  def service_provider
    return unless identity
    @service_provider ||= identity.service_provider(contact_list: self)
  end

  def provider_set?
    ServiceProvider::Adapters.exists? provider_token
  end

  def embed_code?
    ServiceProvider.embed_code? identity&.provider
  end

  def webhook?
    identity&.provider == 'webhooks'
  end

  def zapier?
    identity&.provider == 'zapier'
  end

  def tags
    data['tags'] || []
  end

  private

  def provider_valid
    errors.add(:provider, 'is not valid') unless provider_set? && identity&.provider
  end

  def provider_credentials_exist
    errors.add(:provider, 'credentials have not been set yet') unless identity&.provider == provider_token
  end

  def clean_embed_code
    return if data['embed_code'].blank? || identity.blank?
    data['embed_code'] = CleanEmbedCode.new(data['embed_code']).call
  end

  def reject_empty_data_values
    return unless data
    self.data = data.delete_if { |_, v| v.blank? }
  end

  def embed_code_exists?
    errors.add(:base, 'Embed code cannot be blank') if data['embed_code'].blank?
  end

  def embed_code_valid?
    return if ExtractEmbedForm.new(data['embed_code']).call.valid?
    errors.add(:base, 'Embed code is invalid')
  end

  def webhook_url_valid?
    uri = Addressable::URI.parse(data['webhook_url'])
    return errors.add(:base, 'webhook URL cannot be blank') if uri.blank?
    errors.add(:base, 'webhook protocol must be either http or https') unless %w[http https].include?(uri.scheme)

    begin
      Socket.gethostbyname(uri.host)
    rescue SocketError
      errors.add(:base, 'could not connect to the webhook URL')
    end
  end

  def nullify_identity_reference
    # Identity#has_many :contact_lists, dependent: :nullify doesn't work because
    # it wants to update a contact list with `deleted_at` being NULL which at
    # this point is not the case as the record is already marked as being
    # deleted (thanks, paranoia), so we have to nullify the reference manually
    # https://github.com/rubysherpas/paranoia/issues/413
    update_attribute(:identity_id, nil) if persisted?
  end
end
