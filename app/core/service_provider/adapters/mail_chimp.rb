module ServiceProvider::Adapters
  class MailChimp < Base
    HELLO_BAR_SOURCE = 'Hello Bar'.freeze

    configure do |config|
      config.client_id = Settings.identity_providers['mailchimp']['client_id']
      config.secret = Settings.identity_providers['mailchimp']['secret']
      config.supports_double_optin = true
      config.oauth = true
    end

    rescue_from Gibbon::MailChimpError, with: :handle_exeption

    def initialize(identity)
      super identity, Gibbon::Request.new(
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
      response = client.lists.retrieve(params: { count: 100 })
      response.body['lists'].presence || []
    end

    def prepare_params(subscriber_params)
      email, name, double_optin = subscriber_params.values_at :email, :name, :double_optin

      { email_address: email }.tap do |body|
        body[:status] = double_optin ? 'pending' : 'subscribed'
        body[:merge_fields] = { SOURCE: HELLO_BAR_SOURCE }

        if name.present?
          first_name, last_name = name.split(' ', 2)

          body[:merge_fields][:FNAME] = first_name if first_name.present?
          body[:merge_fields][:LNAME] = last_name if last_name.present?
        end
      end
    end

    def handle_exeption(exception)
      case exception.title
      when 'Member Exists'
        ignore_error exception
      when 'Invalid Resource'
        raise ServiceProvider::InvalidSubscriberError, exception.detail
      when 'Resource Not Found', 'API Key Invalid'
        notify_user_about_unauthorized_error
      when 'Net::ReadTimeout'
        ignore_error exception
      else
        raise ServiceProvider::ConnectionProblemError if connection_problem?(exception)
        raise exception
      end
    end

    def connection_problem?(exception)
      exception.message =~ /Net::OpenTimeout|execution expired/
    end
  end
end
