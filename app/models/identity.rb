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

  before_save :cleanse_embed_code

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
    if provider_config[:requires_embed_code]
      !embed_code.nil? and embed_code.length > 0
    else
      credentials.present?
    end
  end

  def working?
    if provider_config[:requires_embed_code]
      embed_code_valid?
    else
      credentials.present? # we later need to know if these credentials actually work/sync
    end
  end

  def embed_code_valid?
    return false if embed_code.blank?
    service_provider.embed_code_valid?
  end

  def type
    provider_config[:type]
  end

  def provider_config
    Hellobar::Settings[:identity_providers][provider.to_sym]
  end

  def as_json(options = nil)
    extra['raw_info'].select! {|k,v| %w(user_id username).include? k } if extra['raw_info']
    extra['lists'] = extra['lists'].try(:collect) {|h| h.select {|k,v| %w(id web_id name).include? k } }
    super
  end

  def service_provider
    @service_provider ||= service_provider_class.new(:identity => self)
  end

  def service_provider_class
    const_name = provider_config[:service_provider_class] || provider_config[:name]
    ServiceProviders.const_get(const_name, false)
  end

  def destroy_and_notify_user
    if user = site.owner
      MailerGateway.send_email("Integration Sync Error", user.email, {:integration_name => provider_config[:name], :link => site_contact_lists_url(site, :host => Hellobar::Settings[:host])})
    end

    self.destroy
  end

  private

  def cleanse_embed_code
    return unless embed_code
    self.embed_code = embed_code.tr("“”‘’", %{""''})
                                .gsub(/\P{ASCII}/, '')
  end
end
