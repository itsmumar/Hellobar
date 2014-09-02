require 'synchronizer'

module EmailSynchronizer
  extend Synchronizer

  ESP_ERROR_CLASSES = [
    Gibbon::MailChimpError,
    CreateSend::RevokedOAuthToken,
    URI::InvalidURIError,
    ArgumentError,
    RestClient::ResourceNotFound
  ]

  ESP_NONTRANSIENT_ERRORS = [
    "Invalid MailChimp List ID",
    "Invalid Mailchimp API Key",
    "This account has been deactivated",
    "122: Revoked OAuth Token",
    "bad URI",
    "bad value for range",
    "404 Resource Not Found"
  ]

  # Extracted from contact_list#subscribe_all_emails_to_list!
  def sync_all!
    return unless syncable?
    
    timestamp = last_synced_at || Time.at(0) # sync from last sync, or for all time
    Rails.logger.info "Syncing emails later than #{timestamp}"

    perform_sync do
      contacts = Hello::DataAPI.get_contacts(self, timestamp.to_i, force: true)
      contacts.in_groups_of(1000, false).each do |group|
        group = group.map{ |g| {:email => g[0], :name => g[1].blank? ? nil : g[1], :created_at => g[2]} }
        batch_subscribe(data["remote_id"], group, double_optin)
      end
    end
  rescue *ESP_ERROR_CLASSES => e
    if ESP_NONTRANSIENT_ERRORS.any?{|message| e.to_s.include?(message)}
      Raven.capture_exception(e)
      identity.destroy_and_notify_user
    else
      raise e
    end
  end

  delegate :batch_subscribe, to: :service_provider

  # Extracted from embed_code_provider#subscribe!
  def sync_one!(email, name, options={})
    perform_sync do
      if oauth?
        subscribe(data["remote_id"], email, name, double_optin)
      else
        params = subscribe_params(email, name, double_optin)
        HTTParty.post(action_url, body: params)
      end
    end
  end

  delegate :subscribe, to: :service_provider
  delegate :subscribe_params, to: :service_provider
  delegate :action_url, to: :service_provider

  private

  def perform_sync
    yield
    update_column :last_synced_at, Time.now
  end
end
