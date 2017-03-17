class ServiceProviders::ConstantContact < ServiceProviders::Email
  def initialize(opts = {})
    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(provider: 'constant_contact').first
      raise 'Site does not have a stored Constant Contact identity' unless identity
    end

    @token = identity.credentials['token']
    @client = ConstantContact::Api.new(Hellobar::Settings[:identity_providers][:constantcontact][:app_key])
  end

  def lists
    @client.lists(@token).map { |l| { 'id' => l.id, 'name' => l.name } }
  end

  def subscribe(list_id, email, name = nil, double_optin = true)
    cc_list = @client.list(@token, list_id)
    cc_contact = ConstantContact::Components::Contact.new
    cc_email = ConstantContact::Components::EmailAddress.new

    cc_email.email_address = email
    cc_contact.email_addresses = [cc_email]
    cc_contact.lists = [cc_list]
    cc_contact.first_name, cc_contact.last_name = (name || '').split(' ')

    add_contact(cc_contact, double_optin)
  rescue RestClient::Conflict
    cc_contact = @client.contact_by_email(@token, email).results[0]
    cc_contact.lists ||= []
    cc_contact.lists << cc_list

    update_contact(cc_contact, double_optin)
  end

  def update_contact(contact, double_optin = true)
    @client.update_contact(@token, contact, double_optin)
  rescue RestClient::Conflict
    # this can still fail a second time if CC isn't happy with how the data matches. for some reason.
    return true
  rescue RestClient::BadRequest => e
    if e.inspect =~ /not be opted in using/
      # sometimes constant contact doesn't allow you to skip double opt-in, and lets you know by exploding
      # if that happens, try adding contact again WITH double opt-in
      @client.update_contact(@token, contact, true)
    else
      raise e
    end
  end

  def add_contact(contact, double_optin)
    @client.add_contact(@token, contact, double_optin)
  rescue RestClient::BadRequest => e
    if e.inspect =~ /not a valid email address/
      # if the email is not valid, CC will raise an exception and we end up here
      # when this happens, just return true and continue
      return true
    elsif e.inspect =~ /not be opted in using/
      # sometimes constant contact doesn't allow you to skip double opt-in, and lets you know by exploding
      # if that happens, try adding contact again WITH double opt-in
      @client.add_contact(@token, contact, true)
    else
      raise e
    end
  end

  # send subscribers in [{:email => '', :name => ''}, {:email => '', :name => ''}] format
  def batch_subscribe(list_id, subscribers, _double_optin = true)
    contacts = subscribers.map do |subscriber|
      first, last = (subscriber[:name] || '').split(' ')

      ConstantContact::Components::AddContactsImportData.new.tap do |data|
        data.first_name = first
        data.last_name = last
        data.add_email(subscriber[:email])
      end
    end

    lists = [list_id]
    columns = ['E-Mail', 'First Name', 'Last Name']
    activity = ConstantContact::Components::AddContacts.new(contacts, lists, columns)

    @client.add_create_contacts_activity(@token, activity)
  rescue RestClient::BadRequest => e
    raise e unless e.inspect =~ /not a valid email/

    # if any of the emails in a batch is invalid, the request will be rejected, so we try to naively select only valid addresses and try again
    pattern = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}/
    valid_subscribers = subscribers.select { |s| s[:email] =~ pattern }

    if valid_subscribers.count < subscribers.count
      # to prevent an infinite loop, only retry if we were able to pare the subscribers array down
      batch_subscribe(list_id, valid_subscribers)
    else
      return true
    end
  end
end
