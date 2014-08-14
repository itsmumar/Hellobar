class ContactList < ActiveRecord::Base
  include GuaranteedQueue::Delay
  include DeserializeWithErrors

  EPS_ERROR_CLASSES = [
    Gibbon::MailChimpError,
    CreateSend::RevokedOAuthToken,
    URI::InvalidURIError,
    ArgumentError,
    RestClient::ResourceNotFound
  ]

  EPS_NONTRANSIENT_ERRORS = [
    "Invalid MailChimp List ID",
    "Invalid Mailchimp API Key",
    "This account has been deactivated",
    "122: Revoked OAuth Token",
    "bad URI",
    "bad value for range",
    "404 Resource Not Found"
  ]

  attr_accessor :provider

  belongs_to :site
  belongs_to :identity

  has_many :site_elements

  serialize :data, Hash

  before_validation :set_identity

  validates :name, :presence => true
  validates :site, :association_exists => true
  validate :provider_credentials_exist, :if => :provider_set?

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
    identity && data && data["remote_name"] && data["remote_id"]
  end

  def service_provider
    return nil unless syncable?
    @provider ||= identity.service_provider
  end

  def sync(options = {})
    return false unless syncable?

    options.reverse_merge! immediate: false

    if options[:immediate]
      subscribe_all_emails_to_list!
    else
      delay :subscribe_all_emails_to_list!
    end
  end

  def sync!
    sync(immediate: true)
  end

  def subscribers
    @subscribers ||= Hello::EmailData.get_all_emails(id).sort_by{|s| s[:created_at]}.reverse
  end

  def num_subscribers
    @num_subscribers ||= Hello::EmailData.num_emails(id)
  end

  def to_csv
    CSV.generate do |csv|
      headers = [
        "Email",
        "Name",
        "Timestamp"
      ]

      csv << headers

      subscribers.each do |subscriber|
        csv << [
          subscriber[:email],
          subscriber[:name],
          subscriber[:created_at]
        ]
      end
    end
  end

  def provider_set?
    ![nil, "", 0, "0"].include?(provider)
  end

  def set_identity
    self.identity = provider_set? ? site.identities.where(:provider => provider).first : nil
  end

  protected

  def subscribe_all_emails_to_list!
    return unless syncable?

    timestamp = last_synced_at || Time.at(0) # sync from last sync, or for all time
    Rails.logger.info "Syncing emails later than #{timestamp}"

    Hello::EmailData.get_emails_since(id, timestamp.to_i).in_groups_of(1000).collect do |group|
      service_provider.batch_subscribe(data["remote_id"], group.compact, double_optin) unless group.compact.empty?
    end

    update_column :last_synced_at, Time.now
  rescue *EPS_ERROR_CLASSES => e
    if EPS_NONTRANSIENT_ERRORS.any?{|message| e.to_s.include?(message)}
      Raven.capture_exception(e)
      self.identity.destroy_and_notify_user
    else
      raise e
    end
  end

  private

  def provider_credentials_exist
    errors.add(:provider, "credentials have not been set yet") unless identity && identity.provider == provider
  end
end
