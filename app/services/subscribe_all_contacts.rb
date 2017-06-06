class SubscribeAllContacts
  # @param [ContactList] contact_list
  def initialize(contact_list)
    @contact_list = contact_list
    @list_id = contact_list.data['remote_id']
    @provider = ServiceProviders::Provider.new(contact_list.identity, contact_list)
  end

  def call
    return unless contact_list.syncable?

    Rails.logger.info "Syncing all emails for contact_list #{ contact_list.id }"

    retrieve_subscribers do |subscribers|
      provider.batch_subscribe list_id, subscribers
    end
  end

  private

  attr_reader :provider, :contact_list, :list_id

  def retrieve_subscribers
    return if contacts.blank?

    contacts.in_groups_of(1000, false).each do |group|
      yield group.map { |email, name| { email: email, name: name } }
    end
  end

  def contacts
    @contacts ||= Hello::DataAPI.contacts(contact_list)
  end
end
