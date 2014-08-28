require 'synchronizer'

module Synchronizers::Email
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
    return unless contact_list.syncable?
    
    timestamp = last_synced_at || Time.at(0) # sync from last sync, or for all time
    Rails.logger.info "Syncing emails later than #{timestamp}"

    Hello::DataAPI.get_contacts(self, timestamp.to_i, force: true).in_groups_of(1000).collect do |group|
      group = group.compact.map{ |g| {:email => g[0], :name => g[1].blank? ? nil : g[1], :created_at => g[2]} }
      batch_subscribe(data["remote_id"], group.compact, double_optin) unless group.compact.empty?
    end

    update_column :last_synced_at, Time.now
  rescue *ESP_ERROR_CLASSES => e
    if ESP_NONTRANSIENT_ERRORS.any?{|message| e.to_s.include?(message)}
      Raven.capture_exception(e)
      self.identity.destroy_and_notify_user
    else
      raise e
    end
  end

  # Extracted from embed_code_provider#subscribe!
  def sync_one!(item, name, options={})
    name_params_hash = if name_params.empty?
      {}
    elsif name_params.count > 1
      names = name.split(' ')
      params = name_params.find {|p| p.match(/first|fname/) }, name_params.find {|p| p.match(/last|lname/) }

      {
        params.first => names.first,
        params.last => names.last
      }
    else
      { name_param => name }
    end

    params = required_params
    params.merge!(email_param => email)
    params.merge! name_params_hash

    HTTParty.post(action_url, body: params)
  end
end
