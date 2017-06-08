class SubscribeContact
  # @return [SubscribeContactWorker::Contact]
  def initialize(contact)
    @contact_list = contact.contact_list
    @provider = ServiceProvider.new(contact_list.identity, contact_list)
    @email = contact.email
    @name = contact.fields
  end

  def call
    with_log_entry do
      provider.subscribe(email: email, name: name)
    end
  end

  private

  attr_reader :email, :name, :contact_list, :provider

  def with_log_entry
    log_entry = contact_list.contact_list_logs.create!(email: email, name: name)
    yield
    log_entry.update(completed: true)
  rescue => e
    log_entry.update(completed: false, error: e.to_s)
    raise e
  end
end
