class SubscribeAllContacts
  # @param [ContactList] contact_list
  def initialize(contact_list)
    @contact_list = contact_list
    @provider = ServiceProviders::Provider.new(contact_list.identity, contact_list)
  end

  def call
    return unless contact_list.syncable?

    retrieve_subscribers do |subscribers|
      provider.batch_subscribe subscribers
    end
  end

  private

  attr_reader :provider, :contact_list

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
