module ServiceProvider::Adapters
  class MadMimi < Base
    configure do |config|
      config.requires_api_key = true
      config.requires_username = true
    end

    def initialize(identity)
      super ::MadMimi.new(identity.credentials['username'], identity.api_key, raise_exceptions: true)
    end

    def lists
      client.lists.dig('lists', 'list').map { |list| list.slice('id', 'name') }
    end

    def subscribe(list_id, params)
      options = {}
      options[:name] = params[:name] if params[:name].present?

      client.add_to_list(params[:email], list_id, options)
    end

    private

    def test_connection
      client.lists
    end
  end
end
