module ServiceProvider::Adapters
  class Webhook < FaradayClient
    configure do |config|
      config.requires_webhook_url = true
    end

    def initialize(contact_list)
      return unless contact_list
      @contact_list = contact_list
      @method = contact_list.data.fetch('webhook_method', 'GET').downcase.to_sym
      super contact_list.data.fetch('webhook_url', '')
    end

    def lists
    end

    def tags
    end

    def subscribe(_list_id, params)
      params = determine_params(params.slice(:email, :name))

      client.public_send(@method) do |request|
        if @method == :get
          request.params = params
        else
          request.body = params
        end
      end
    end

    private

    def determine_params(email:, name: nil)
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
      @contact_list.site_elements.find do |element|
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
        field['label'].parameterize('_')
      end
    end

    private

    def test_connection
      Socket.gethostbyname(client.url_prefix.host)
    end
  end
end
