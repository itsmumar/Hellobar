class Identity < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :site

  has_many :contact_lists

  # credentials and extra are populated by the third party service at the end of the OAuth flow
  serialize :credentials, JSON
  serialize :extra, JSON

  validates :provider, :presence => true,
                       :uniqueness => {:scope => :site_id},
                       :inclusion => {:in => Hellobar::Settings[:identity_providers].keys.map(&:to_s)}

  validates :site, :association_exists => true

  scope :by_type, ->(type) {where(:provider => Hellobar::Settings[:identity_providers].select{|k, v| v[:type] == type}.map{|k, v| k.to_s})}
  scope :active, -> { where('credentials IS NOT NULL') }

  def self.find_or_initialize_by_site_id_and_provider(site_id, provider)
    if identity = Identity.where(:site_id => site_id, :provider => provider).first
      identity
    else
      Identity.new(:site_id => site_id, :provider => provider)
    end
  end

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
  alias :provider_config :provider_settings

  def as_json(options = nil)
    extra['raw_info'].select! {|k,v| %w(user_id username).include? k } if extra['raw_info']
    extra['lists'] = extra['lists'].try(:collect) {|h| h.select {|k,v| %w(id web_id name).include? k } }
    super
  end

  def service_provider(options={})
    contact_list = options[:contact_list]
    if !contact_list.is_a?(ContactList) and service_provider_class.embed_code?
      fail ArgumentError, ":contact_list is required for embed code identities"
    end
    @service_provider ||= service_provider_class.new(:identity => self, :contact_list => contact_list)
  end

  def service_provider_class
    ServiceProvider[provider.to_sym]
  end

  def destroy_and_notify_user
    if user = site.owner
      MailerGateway.send_email("Integration Sync Error", user.email, {:integration_name => provider_settings[:name], :link => site_contact_lists_url(site, :host => Hellobar::Settings[:host])})
    end

    self.destroy
  end

  # Deprecated
  # TODO -Remove once the `embed_code` column is removed from Identities
  def embed_code=(embed_code)
    fail NoMethodError
  end
end
