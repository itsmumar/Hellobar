module ServiceProvider::Adapters
  class ConstantContact < Base
    EMAIL_REGEXP = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}/

    configure do
      config.app_key = Settings.identity_providers['constantcontact']['app_key']
      config.app_secret = Settings.identity_providers['constantcontact']['app_secret']
      config.oauth = true
    end

    rescue_from RestClient::Unauthorized, with: :destroy_identity

    def initialize(identity)
      @identity = identity
      super ::ConstantContact::Api.new(config.app_key, identity.credentials['token'])
    end

    def lists
      client.get_lists.map { |l| { 'id' => l.id, 'name' => l.name } }
    end

    def subscribe(list_id, params)
      list = client.get_list(list_id)
      add_contact(list, make_contact(list, params), params[:double_optin])
    end

    def batch_subscribe(list_id, subscribers, double_optin: nil) # rubocop:disable Lint/UnusedMethodArgument
      import = make_import(subscribers)
      activity = ::ConstantContact::Components::AddContacts.new(import, [list_id], ['E-Mail', 'First Name', 'Last Name'])

      client.add_create_contacts_activity(activity)
    end

    private

    def make_import(subscribers)
      valid_subscribers = subscribers.select { |subscriber| subscriber[:email] =~ EMAIL_REGEXP }

      valid_subscribers.map do |subscriber|
        first, last = subscriber.fetch(:name, '').split(' ')

        ::ConstantContact::Components::AddContactsImportData.new.tap do |data|
          data.first_name = first if first.present?
          data.last_name = last if last.present?
          data.add_email(subscriber[:email])
        end
      end
    end

    def make_contact(list, params)
      ::ConstantContact::Components::Contact.new.tap do |contact|
        email = ::ConstantContact::Components::EmailAddress.new(params[:email])

        contact.email_addresses = [email]
        contact.add_list(list)
        contact.first_name, contact.last_name = params[:name].split(' ') if params[:name].present?
      end
    end

    def add_contact(list, contact, double_optin)
      client.add_contact(contact, double_optin)
    rescue RestClient::Conflict
      contact = client.get_contact_by_email(contact.email_addresses.last.email_address).results[0]
      contact.add_list(list)
      update_contact(contact)
    rescue RestClient::BadRequest => e
      # if the email is not valid, CC will raise an exception and we end up here
      # when this happens, just return true and continue
      return if e.inspect =~ /not a valid email address/
      raise e unless e.inspect =~ /not be opted in using/

      # sometimes constant contact doesn't allow you to skip double opt-in, and lets you know by exploding
      # if that happens, try adding contact again WITH double opt-in
      client.add_contact(contact, true)
    end

    def update_contact(contact)
      client.update_contact(contact, true)
    rescue RestClient::Conflict # rubocop:disable Lint/HandleExceptions
      # do nothing
    end

    def destroy_identity
      @identity.destroy_and_notify_user
    end
  end
end
