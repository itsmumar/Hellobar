module ServiceProviders
  module Adapters
    class ConstantContact < Base
      EMAIL_REGEXP = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}/

      configure do
        config.app_key = Settings.identity_providers['constantcontact']['app_key']
        config.app_secret = Settings.identity_providers['constantcontact']['app_secret']
        config.oauth = true
      end

      def initialize(identity)
        @token = identity.credentials['token']
        super ::ConstantContact::Api.new(config.app_key)
      end

      def lists
        client.get_lists(@token).map { |l| { 'id' => l.id, 'name' => l.name } }
      end

      def subscribe(list_id, params)
        list = client.get_list(@token, list_id)
        add_contact(make_contact(list, params), params[:double_optin])
      end

      def batch_subscribe(list_id, subscribers, double_optin: nil) # rubocop:disable Lint/UnusedMethodArgument
        import = make_import(subscribers)
        activity = ::ConstantContact::Components::AddContacts.new(import, [list_id], ['E-Mail', 'First Name', 'Last Name'])

        client.add_create_contacts_activity(@token, activity)
      rescue RestClient::BadRequest => e
        retry_if_invalid_email(e, list_id, subscribers)
      end

      private

      def retry_if_invalid_email(exception, list_id, subscribers)
        raise exception unless exception.to_s =~ /not a valid email/

        # if any of the emails in a batch is invalid, the request will be rejected, so we try to naively select only valid addresses and try again
        valid_subscribers = subscribers.select { |s| s[:email] =~ EMAIL_REGEXP }

        return true unless valid_subscribers.count < subscribers.count

        # to prevent an infinite loop, only retry if we were able to pare the subscribers array down
        batch_subscribe(list_id, valid_subscribers)
      end

      def make_import(subscribers)
        subscribers.map do |subscriber|
          first, last = (subscriber[:name] || '').split(' ')

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

      def add_contact(contact, double_optin)
        client.add_contact(@token, contact, double_optin)
      rescue RestClient::Conflict
        contact = client.get_contact_by_email(@token, email).results[0]
        contact.add_list(list)
        update_contact(contact, double_optin)
      rescue RestClient::BadRequest => e
        # if the email is not valid, CC will raise an exception and we end up here
        # when this happens, just return true and continue
        return true if e.inspect =~ /not a valid email address/
        raise e unless e.inspect =~ /not be opted in using/

        # sometimes constant contact doesn't allow you to skip double opt-in, and lets you know by exploding
        # if that happens, try adding contact again WITH double opt-in
        client.add_contact(@token, contact, true)
      end

      def update_contact(contact, double_optin = true)
        client.update_contact(@token, contact, double_optin)
      rescue RestClient::Conflict
        # this can still fail a second time if CC isn't happy with how the data matches. for some reason.
        return true
      rescue RestClient::BadRequest => e
        # sometimes constant contact doesn't allow you to skip double opt-in, and lets you know by exploding
        # if that happens, try adding contact again WITH double opt-in
        raise e unless e.inspect =~ /not be opted in using/
        client.update_contact(@token, contact, true)
      end
    end
  end
end
