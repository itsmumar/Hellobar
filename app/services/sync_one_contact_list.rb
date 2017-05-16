class SyncOneContactList < SyncAllContactList
  def initialize(contact_list, email, name)
    super(contact_list)
    @email = email
    @name = name
    clean_up_params!
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

  def clean_up_params!
    # Ensure rake-task quotes are removed
    start_end_quotes = /^"|"$/
    @name = name.gsub(start_end_quotes, '')
    @email = email.gsub(start_end_quotes, '')

    # Remove name if rake interpreted is as "nil"
    @name = nil if name == 'nil'
  end

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
