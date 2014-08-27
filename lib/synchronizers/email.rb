module Synchronizers
end

module Synchronizers::Email < Synchronizer

  def self.using_contact_list(contact_list)
    new(syncable: contact_list)
  end

  def initialize(syncable:)
    @syncable = syncable
  end

  # extracted from contact_list#subscribe_all_emails_to_list!
  def sync_all!
    return unless syncable?

    timestamp = last_synced_at || Time.at(0) # sync from last sync, or for all time
    Rails.logger.info "Syncing emails later than #{timestamp}"

    Hello::DataAPI.get_contacts(self, timestamp.to_i, force: true).in_groups_of(1000).collect do |group|
      group = group.compact.map{ |g| {:email => g[0], :name => g[1].blank? ? nil : g[1], :created_at => g[2]} }
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

  # extracted from embed_code_provider#subscribe!
  def sync_one!(item, name, options={})
    HTTParty.post(action_url, body: params)
  end
end
