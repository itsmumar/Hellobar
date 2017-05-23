class SubscribeAllContacts
  ESP_ERROR_CLASSES = [
    Gibbon::MailChimpError,
    CreateSend::RevokedOAuthToken,
    URI::InvalidURIError,
    ArgumentError,
    RestClient::ResourceNotFound
  ].freeze

  ESP_NONTRANSIENT_ERRORS = [
    'Invalid MailChimp List ID',
    'Invalid Mailchimp API Key',
    'This account has been deactivated',
    '122: Revoked OAuth Token',
    '404 Resource Not Found'
  ].freeze

  # @param [ContactList] contact_list
  def initialize(contact_list)
    @contact_list = contact_list
    @list_id = contact_list.data['remote_id']
    @double_optin = contact_list.double_optin
  end

  def call
    return unless contact_list.syncable?

    Rails.logger.info "Syncing all emails for contact_list #{ contact_list.id }"

    perform_sync do
      contacts = Hello::DataAPI.contacts(contact_list) || []
      contacts.in_groups_of(1000, false).each do |group|
        if api_call?
          group = group.map { |g| { email: g[0], name: g[1].blank? ? nil : g[1], created_at: g[2] } }
          subscribe(group)
        else
          group.each do |g|
            make_request subscribe_params(g[0], g[1])
          end
        end
      end
    end
  end

  private

  attr_reader :contact_list, :list_id, :double_optin

  def api_call?
    contact_list.oauth? || contact_list.api_key? || contact_list.webhook?
  end

  def subscribe(subscribers)
    contact_list.service_provider.batch_subscribe(list_id, subscribers, double_optin)
  end

  def subscribe_params(email, name)
    contact_list.service_provider.subscribe_params(email, name, double_optin)
  end

  def action_url
    contact_list.service_provider.action_url
  end

  def perform_sync
    yield
  rescue *ESP_ERROR_CLASSES => e
    handle_error e
  end

  def handle_error(e)
    Raven.capture_exception(e)
    raise e unless ESP_NONTRANSIENT_ERRORS.any? { |message| e.to_s.include?(message) }

    clear_identity_on_failure(e)
  end

  def clear_identity_on_failure(e)
    return unless contact_list.oauth?

    Rails.logger.warn "Removing identity #{ contact_list.identity.try(:id) }\n#{ e.message }"
    contact_list.identity.try(:destroy_and_notify_user)
  end

  def make_request(params)
    HTTParty.post(action_url, body: params)
  end
end
