class Identity < ApplicationRecord
  belongs_to :site

  has_many :contact_lists, dependent: :nullify

  # credentials and extra are populated by the third party service at the end of the OAuth flow
  serialize :credentials, JSON
  serialize :extra, JSON

  validates :provider, presence: true,
                       uniqueness: { scope: :site_id },
                       inclusion: { in: proc { ServiceProvider::Adapters.keys.map(&:to_s) } }

  validates :site, association_exists: true
  validate :service_provider_valid

  scope :by_type, ->(type) { where(provider: Settings.identity_providers.select { |_, v| v['type'] == type }.map { |k, _| k.to_s }) }
  scope :active, -> { where('credentials IS NOT NULL') }

  def self.store_to_session(session, auth)
    data = auth.slice('provider', 'credentials', 'extra')
    data['extra'] = data.fetch('extra', {}).slice('metadata', 'accounts', 'app_url')
    session[:omniauth_provider] = data
    from_session session
  end

  def self.from_session(session, provider: nil, clear: false)
    omniuth = session[:omniauth_provider]
    session.delete(:omniauth_provider) if clear
    return unless omniuth
    return if provider && provider != omniuth['provider']

    new(
      provider: omniuth['provider'],
      extra: omniuth['extra'],
      credentials: omniuth['credentials']
    )
  end

  def as_json(options = nil)
    extra['raw_info']&.select! { |k, _| %w[user_id username].include? k }
    extra['lists'] = extra['lists'].try(:collect) { |h| h.select { |k, _| %w[id web_id name].include? k } }

    super
  end

  def provider_name
    I18n.t(provider, scope: :service_providers)
  end

  def provider_icon_path
    "providers/#{ provider }.png"
  end

  def service_provider(contact_list: nil)
    ServiceProvider.new(self, contact_list)
  end

  private

  def service_provider_valid
    return if service_provider&.connected?
    errors.add(:provider, 'could not be verified.')
  end
end
