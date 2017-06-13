module ServiceProvider::Adapters
  class MailChimp < Base
    configure do |config|
      config.client_id = Settings.identity_providers['mailchimp']['client_id']
      config.secret = Settings.identity_providers['mailchimp']['secret']
      config.supports_double_optin = true
      config.oauth = true
    end

    rescue_from Gibbon::MailChimpError, with: :destroy_identity_if_needed

    def initialize(identity)
      @identity = identity
      super Gibbon::Request.new(
        api_key: identity.credentials['token'],
        api_endpoint: identity.extra['metadata']['api_endpoint']
      )
    end

    def lists
      raw_lists.map { |raw_list| raw_list.slice('id', 'name') }
    end

    def subscribe(list_id, params)
      client.lists(list_id).members.create body: prepare_params(params)
    end

    private

    def raw_lists
      raw_lists = client.lists.retrieve(params: { count: 100 })['lists']
      raw_lists.presence || []
    end

    def prepare_params(subscriber, double_optin = true)
      email, name = subscriber.values_at(:email, :name)

      { email_address: email }.tap do |body|
        body[:status] = double_optin ? 'pending' : 'subscribed'

        if name.present?
          first_name, last_name = name.split(' ', 2)
          body[:merge_fields] = {}
          body[:merge_fields][:FNAME] = first_name if first_name.present?
          body[:merge_fields][:LNAME] = last_name if last_name.present?
        end
      end
    end

    def destroy_identity_if_needed(exception)
      raise exception unless exception.title.in? ['Resource Not Found', 'API Key Invalid']
      @identity.destroy_and_notify_user
    end
  end
end
