class Identity < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :site

  has_many :contact_lists

  # credentials and extra are populated by the third party service at the end of the OAuth flow
  serialize :credentials, JSON
  serialize :extra, JSON

  validates :provider, presence: true,
                       uniqueness: { scope: :site_id },
                       inclusion: { in: Hellobar::Settings[:identity_providers].keys.map(&:to_s) }

  validates :site, association_exists: true
  validate :service_provider_valid

  scope :by_type, ->(type) { where(provider: Hellobar::Settings[:identity_providers].select { |_, v| v[:type] == type }.map { |k, _| k.to_s }) }
  scope :active, -> { where('credentials IS NOT NULL') }

  # When an activity is active, it is saved, credentials are present, and it is being used.
  # Sites should only allow one active identity at a time for each type.
  def active?
    persisted? and filled_out?
  end

  def filled_out?
    credentials.present?
  end

  def working?
    credentials.present? # we later need to know if these credentials actually work/sync
  end

  def type
    provider_settings[:type]
  end

  def provider_settings
    service_provider_class.settings
  end
  alias provider_config provider_settings

  def as_json(options = nil)
    extra['raw_info'].select! { |k, _| %w(user_id username).include? k } if extra['raw_info']
    extra['lists'] = extra['lists'].try(:collect) { |h| h.select { |k, _| %w(id web_id name).include? k } }
    super
  end

  def service_provider(options = {})
    return nil if service_provider_class.nil?
    @service_provider ||= service_provider_class.new(identity: self, contact_list: options[:contact_list])
  rescue *EmailSynchronizer::ESP_ERROR_CLASSES => e
    if service_provider_class.oauth?
      Rails.logger.warn "Removing identity #{id}\n#{e.message}"
      destroy_and_notify_user
    end
    nil
  end

  def service_provider_class
    ServiceProvider[provider.to_sym]
  end

  def destroy_and_notify_user
    site.owners.each do |user|
      MailerGateway.send_email('Integration Sync Error', user.email, { integration_name: provider_settings[:name], link: site_contact_lists_url(site, host: Hellobar::Settings[:host]) })
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
    cached_provider = @service_provider # Don't cache the results of this
    if service_provider && !service_provider.valid?
      errors.add(:provider, 'could not be verified.')
    end
    @service_provider = cached_provider
  end
end
