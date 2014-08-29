class ContactList < ActiveRecord::Base
  include GuaranteedQueue::Delay
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

  def self.sync_all!
    all.each do |list|
      begin
        list.sync! if list.syncable?
      rescue => e
        # if something goes wrong, we want to know about it, but we don't want to prevent other lists from syncing
        Raven.capture_exception(e)
      end
    end
  end

  def syncable?
    return false unless identity && data

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

    data = Hello::DataAPI.get_contacts(self)
    @subscribers = data ? data.map{|d| {:email => d[0], :name => d[1]}} : []
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
