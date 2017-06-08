class Identity < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :site

  has_many :contact_lists

  # credentials and extra are populated by the third party service at the end of the OAuth flow
  serialize :credentials, JSON
  serialize :extra, JSON

  validates :provider, presence: true,
                       uniqueness: { scope: :site_id },
                       inclusion: { in: proc { ServiceProviders::Adapters.keys.map(&:to_s) } }

  validates :site, association_exists: true
  validate :service_provider_valid

  scope :by_type, ->(type) { where(provider: Settings.identity_providers.select { |_, v| v['type'] == type }.map { |k, _| k.to_s }) }
  scope :active, -> { where('credentials IS NOT NULL') }

  # When an activity is active, it is saved, credentials are present, and it is being used.
  # Sites should only allow one active identity at a time for each type.
  def active?
    persisted? && filled_out?
  end

  def filled_out?
    credentials.present?
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
    ServiceProviders::Provider.new(self, contact_list)
  end

  def destroy_and_notify_user
    site.owners.each do |user|
      MailerGateway.send_email('Integration Sync Error', user.email, integration_name: provider_name, link: site_contact_lists_url(site, host: Settings.host))
    end

    destroy
  end

  def contact_lists_updated
    destroy if contact_lists.count == 0
  end

  # Deprecated
  # TODO -Remove once the `embed_code` column is removed from Identities
  def embed_code=(_embed_code)
    raise NoMethodError
  end

  private

  def service_provider_valid
    return if service_provider&.connected?
    errors.add(:provider, 'could not be verified.')
  end
end
