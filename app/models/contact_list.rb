class ContactList < ActiveRecord::Base
  attr_accessor :provider_token

  belongs_to :site, touch: true # as we want to invalidate cache
  belongs_to :identity, dependent: :destroy

  has_many :site_elements, dependent: :destroy
  has_many :contact_list_logs

  store :data, coder: Hash

  acts_as_paranoid

  before_validation :reject_empty_data_values, :clean_embed_code

  validates :name, presence: true
  validates :site, presence: true, associated: true
  validate :provider_valid, if: :provider_set?
  validate :provider_credentials_exist, if: :provider_set?
  validate :embed_code_exists?, if: :embed_code?
  validate :embed_code_valid?, if: :embed_code?
  validate :webhook_url_valid?, if: :webhook?

  delegate :count, to: :site_elements, prefix: true

  def statuses_for_subscribers(subscribers)
    return [] unless identity
    contact_list_logs.statuses(subscribers)
  end

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

  def subscribers(limit = nil)
    FetchContacts.new(self, limit: limit).call
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
end
