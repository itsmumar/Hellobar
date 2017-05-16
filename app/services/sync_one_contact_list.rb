class SyncOneContactList < SyncAllContactList
  def initialize(contact)
    super(contact.contact_list)
    @email = contact.email
    @name = contact.fields
  end

  def call
    log_entry = contact_list.contact_list_logs.create!(email: email, name: name)

    return unless contact_list.syncable?

    perform_sync(log_entry) do
      if api_call?
        subscribe
      else
        make_simple_request subscribe_params
      end
    end
  end

  private

  attr_reader :contact_list, :email, :name

  def subscribe
    contact_list.service_provider.subscribe(list_id, email, name, double_optin)
  end

  def subscribe_params
    super(email, name)
  end

  def perform_sync(log_entry)
    yield
    log_entry.update(completed: true)
  rescue *ESP_ERROR_CLASSES => e
    handle_error e, log_entry
  rescue => e
    Raven.capture_exception(e)
    log_entry.update(completed: false, error: e.to_s)
    raise e
  end

  def handle_error(e, log_entry)
    Raven.capture_exception(e)
    log_entry.update(completed: false, error: e.to_s)

    raise e unless ESP_NONTRANSIENT_ERRORS.any? { |message| e.to_s.include?(message) }

    clear_identity_on_failure(e)
  end
end
