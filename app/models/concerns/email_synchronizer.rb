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
    'Invalid MailChimp List ID',
    'Invalid Mailchimp API Key',
    'This account has been deactivated',
    '122: Revoked OAuth Token',
    '404 Resource Not Found'
  ]

  # Extracted from contact_list#subscribe_all_emails_to_list!
  def sync_all!
    return unless syncable?

    Rails.logger.info "Syncing all emails for contact_list #{id}"

    perform_sync do
      contacts = Hello::DataAPI.get_contacts(self) || []
      contacts.in_groups_of(1000, false).each do |group|
        if oauth? || api_key? || webhook?
          group = group.map { |g| { :email => g[0], :name => g[1].blank? ? nil : g[1], :created_at => g[2] } }
          batch_subscribe(data['remote_id'], group, double_optin)
        else
          group.each do |g|
            params = subscribe_params(g[0], g[1], double_optin)
            HTTParty.post(action_url, body: params)
          end
        end
      end
    end
  end

  delegate :batch_subscribe, to: :service_provider

  # Extracted from embed_code_provider#subscribe!
  def sync_one!(email, name, options = {})
    log_entry = contact_list_logs.create(email: email, name: name)
    return unless syncable?

    # Ensure rake-task quotes are removed
    start_end_quotes = /^"|"$/
    name.gsub!(start_end_quotes, '')
    email.gsub!(start_end_quotes, '')
    # Remove name if rake interpreted is as "nil"
    name = nil if name == 'nil'

    perform_sync(log_entry) do
      if oauth? || api_key? || webhook?
        subscribe(data['remote_id'], email, name, double_optin)
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

  def perform_sync(log_entry = nil)
    # run something immediately before sync
    yield
    # run something immediately after sync
    log_entry.update(completed: true) if log_entry
  rescue *ESP_ERROR_CLASSES => e
    if log_entry
      log_entry.update(completed: false, error: e.to_s, stacktrace: caller.join("\n"))
    end

    if ESP_NONTRANSIENT_ERRORS.any? { |message| e.to_s.include?(message) }
      Raven.capture_exception(e)
      if oauth?
        # Clear identity on failure
        Rails.logger.warn "Removing identity #{identity.try(:id)}\n#{e.message}"
        identity.try(:destroy_and_notify_user)
      end
    else
      raise e
    end
  rescue => e
    log_entry.update(completed: false, error: e.to_s, stacktrace: caller.join("\n")) if log_entry
    raise e
  end
end
