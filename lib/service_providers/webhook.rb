module ServiceProviders
  class Webhook < ServiceProvider
    attr_reader :contact_list

    def initialize(opts = {})
      @contact_list = opts[:contact_list]
    end

    def client
      @client ||= Faraday.new(url: contact_list.data['webhook_url']) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger unless Rails.env.test?
        faraday.adapter Faraday.default_adapter
      end
    end

    def subscribe(_, email, name = nil, _double_optin = true)
      method = contact_list.data['webhook_method'].downcase.to_sym
      params = determine_params(email, name)

      client.public_send(method) do |request|
        if method == :get
          request.params = params
        else
          request.body = params
        end
      end
    end

    def batch_subscribe(_list_id, subscribers, _double_optin = true)
      subscribers.each do |subscriber|
        subscribe(nil, subscriber[:email], subscriber[:name])
      end
    end

    def valid?
      true
    end

    private

    def determine_params(email, name)
      return { email: email, name: name } unless name.to_s.include?(',')

      fields = extract_fields(email, name)
      site_element = find_related_site_element(fields)
      field_names = extract_field_names(site_element)
      field_names.zip(fields).to_h.symbolize_keys
    end

    def extract_fields(email, name)
      return [email] unless name

      other_fields = name.split(',')
      [email, *other_fields]
    end

    # TODO: this method is a terrible, terrible, ter-rib-le hack
    # it should be removed with the introduction of proper support for custom fields on backend application
    # we had no choice...
    def find_related_site_element(fields)
      contact_list.site_elements.find do |element|
        select_enabled_fields(element.settings).count == fields.count
      end
    end

    def select_enabled_fields(settings)
      settings ||= {}
      settings.fetch(:fields_to_collect, []).select { |field| field['is_enabled'] }
    end

    def extract_field_names(site_element)
      return ['email'] unless site_element

      field_names = select_enabled_fields(site_element.settings).map(&method(:determine_field_name))
      field_names.unshift field_names.delete('email')
    end

    def determine_field_name(field)
      if field['type'] =~ /builtin/
        field['type'].sub('builtin-', '')
      else
        field['label']
      end
    end
  end
end
