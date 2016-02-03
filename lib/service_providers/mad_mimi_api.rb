module ServiceProviders
  class MadMimiApi < ServiceProviders::Email

    def initialize(opts = {})
      if opts[:identity]
        identity = opts[:identity]
      elsif opts[:site]
        identity = opts[:site].identities.find_by_provider!('mad_mimi_api')
        raise "Site does not have a stored MadMimi identity" unless identity
      else
        raise "Must provide an identity through the arguments"
      end

      api_email = identity.credentials["username"]
      api_key = identity.api_key
      raise "Identity does not have a stored MadMimi email" unless api_key
      raise "Identity does not have a stored MadMimi API key" unless api_key

      @client = MadMimi.new(api_email, api_key, { raise_exceptions: true })
    end

    def lists
      lists = client.lists["lists"].try(:[], "list")
      lists.blank? ? [] : lists
    end

    def subscribe(list_id, email, name = nil, double_optin = true)
      name ||= email

      @client.add_to_list(email, list_id, {
        name: name
      })
    end

    def batch_subscribe(list_id, subscribers, double_optin = true)
      @client.add_users(
        subscribers.map { |s| {email: s[:email], name: s[:name] } }
      )
    end

    def valid?
      lists
      true
    rescue
      false
    end
  end
end
