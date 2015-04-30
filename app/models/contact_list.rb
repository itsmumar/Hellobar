require 'queue_worker/queue_worker'

class ContactList < ActiveRecord::Base
  include QueueWorker::Delay
  include DeserializeWithErrors
  include EmailSynchronizer

  EMPTY_PROVIDER_VALUES = [ nil, "", 0, "0" ]

  attr_accessor :provider

  belongs_to :site
  belongs_to :identity

  has_many :site_elements

  serialize :data, Hash

  before_validation :set_identity, :reject_empty_data_values, :clean_embed_code

  validates :name, :presence => true
  validates :site, :association_exists => true
  validate :provider_valid, :if => :provider_set?
  validate :provider_credentials_exist, :if => :provider_set?
  validate :embed_code_exists?, :if => :embed_code?
  validate :embed_code_valid?, :if => :embed_code?

  after_save :sync, :if => :data_changed?
  after_save :notify_identity, :if => :identity_id_changed?
  after_destroy :notify_identity

  def syncable?
    return false unless identity && data && Hellobar::Settings[:syncable]

    if oauth?
      data["remote_name"] && data["remote_id"]
    elsif embed_code?
      data["embed_code"].present?
    end
  end

  def service_provider
    return nil unless syncable?
    @service_provider ||= identity.service_provider(contact_list: self)
  end

  def sync(options = {})
    return false unless syncable?

    options.reverse_merge! immediate: false

    if options[:immediate]
      sync_all!
    else
      delay :sync_all!
    end
  end

  def sync!
    sync(immediate: true)
  end

  def subscribers
    return @subscribers if @subscribers

    data = Hello::DataAPI.get_contacts(self) || []
    @subscribers = data.map{|d| {:email => d[0], :name => d[1], :subscribed_at => d[2].is_a?(Integer) ? Time.at(d[2]) : nil}}
  end

  def subscriber_statuses(_subscribers, force=false)
    return @statuses if @statuses && !force
    @statuses = begin
      if !_subscribers.blank? && service_provider.respond_to?(:subscriber_statuses)
        service_provider.subscriber_statuses(data["remote_id"], _subscribers.map { |x| x[:email] })
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
    !EMPTY_PROVIDER_VALUES.include?(provider)
  end

  def set_identity
    return unless provider.present?

    self.identity = if !provider_set? || service_provider_class.nil?
      nil # Don't create an invalid provider
    elsif embed_code?
      site.identities.find_or_create_by(provider: provider)
    else
      site.identities.find_by(provider: provider)
    end
  end

  def oauth?
    service_provider_class.try(:oauth?)
  end

  def embed_code?
    service_provider_class.try(:embed_code?)
  end

  private
  def notify_identity
    old_identity_id = destroyed? ? identity_id : changes[:identity_id].try(:first)
    Identity.where(id: old_identity_id).first.try(:contact_lists_updated) if old_identity_id
  end

  def provider_valid
    errors.add(:provider, "is not valid") unless provider_set? && identity.try(:provider)
  end

  def provider_credentials_exist
    errors.add(:provider, "credentials have not been set yet") unless identity && identity.provider == provider
  end

  def clean_embed_code
    return unless data['embed_code'] && identity
    self.data['embed_code'] = service_provider.clean_embed_code(data['embed_code'])
  end

  def reject_empty_data_values
    return unless data
    self.data = data.delete_if { |k,v| v.blank? }
  end

  def embed_code_exists?
    errors.add(:base, "Embed code cannot be blank") unless data['embed_code'].present?
  end

  def embed_code_valid?
    service_provider && service_provider.embed_code_valid?
  end

  def service_provider_class
    if identity
      identity.service_provider_class
    elsif provider_set?
      ServiceProvider[provider.to_sym]
    end
  end
end
