class ContactList < ActiveRecord::Base
  EMPTY_PROVIDER_VALUES = [nil, '', 0, '0'].freeze

  attr_accessor :provider_token

  belongs_to :site
  belongs_to :identity

  has_many :site_elements, dependent: :destroy
  has_many :contact_list_logs

  store :data, coder: Hash

  acts_as_paranoid

  before_validation :set_identity, :reject_empty_data_values, :clean_embed_code

  validates :name, presence: true
  validates :site, association_exists: true
  validate :provider_valid, if: :provider_set?
  validate :provider_credentials_exist, if: :provider_set?
  validate :embed_code_exists?, if: :embed_code?
  validate :embed_code_valid?, if: :embed_code?
  validate :webhook_url_valid?, if: :webhook?

  after_save :notify_identity, if: :identity_id_changed?
  after_destroy :notify_identity

  delegate :count, to: :site_elements, prefix: true

  def syncable?
    return false unless identity && data && Settings.syncable

    if oauth?
      data['remote_name'] && data['remote_id']
    elsif embed_code?
      data['embed_code'].present?
    elsif api_key? && app_url?
      identity.api_key? && identity.extra['app_url'].present?
    elsif api_key?
      identity.api_key? && data['remote_name'] && data['remote_id']
    elsif webhook?
      true
    end
  end

  def service_provider
    return nil unless syncable?
    @service_provider ||= identity.service_provider(contact_list: self)
  end

  def subscribers(limit = nil)
    return @subscribers if @subscribers

    data = Hello::DataAPI.contacts(self, limit) || []
    @subscribers = data.map { |d| { email: d[0], name: d[1], subscribed_at: d[2].is_a?(Integer) ? Time.zone.at(d[2]) : nil } }
  end

  def subscriber_statuses(subscribers, force = false)
    return @statuses if @statuses && !force
    @statuses = begin
      if subscribers.present? && service_provider.respond_to?(:subscriber_statuses)
        service_provider.subscriber_statuses(self, subscribers.map { |x| x[:email] })
      else
        {}
      end
    end
  end

  def num_subscribers
    return @num_subscribers if @num_subscribers

    data = Hello::DataAPI.contact_list_totals(site, [self])
    @num_subscribers = data ? data[id.to_s] : 0
  end

  def provider_set?
    !EMPTY_PROVIDER_VALUES.include?(provider_token)
  end

  def set_identity
    return if provider_token.blank?

    self.identity =
      if !provider_set? || service_provider_class.nil?
        nil # Don't create an invalid provider
      elsif embed_code? || (provider_token == 'webhooks')
        site.identities.find_or_create_by(provider: provider_token)
      else
        site.identities.find_by(provider: provider_token)
      end
  end

  def oauth?
    service_provider_class.try(:oauth?).present?
  end

  def embed_code?
    service_provider_class.try(:embed_code?).present?
  end

  def api_key?
    service_provider_class.try(:api_key?).present?
  end

  def app_url?
    service_provider_class.try(:app_url?).present?
  end

  def needs_to_reconfigure?
    return false if webhook?

    if syncable? && !oauth? && !api_key?
      begin
        service_provider.subscribe_params('emailfor@user.com', 'Name namerson', true)
        false
      rescue
        true
      end
    else
      false
    end
  end

  def webhook?
    data['webhook_url'].present?
  end

  def tags
    data['tags'] || []
  end

  def provider_name
    identity && identity.provider.titlecase || 'Hello Bar'
  end

  private

  def notify_identity
    old_identity_id = destroyed? ? identity_id : changes[:identity_id].try(:first)
    Identity.find_by(id: old_identity_id).try(:contact_lists_updated) if old_identity_id
  end

  def provider_valid
    errors.add(:provider, 'is not valid') unless provider_set? && identity.try(:provider)
  end

  def provider_credentials_exist
    errors.add(:provider, 'credentials have not been set yet') unless identity && identity.provider == provider_token
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
    return unless service_provider && !service_provider.embed_code_valid?
    errors.add(:base, 'Embed code is invalid')
  end

  def service_provider_class
    if identity
      identity.service_provider_class
    elsif provider_set?
      ServiceProvider[provider_token]
    end
  end

  def webhook_url_valid?
    uri = Addressable::URI.parse(data['webhook_url'])

    return unless !%w[http https].include?(uri.scheme) || uri.host.blank? || !uri.ip_based? && url !~ /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
    errors.add(:base, 'webhook URL is invalid')
  end
end
