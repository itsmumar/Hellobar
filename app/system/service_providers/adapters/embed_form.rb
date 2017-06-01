module ServiceProviders
  module Adapters
    class EmbedForm < FaradayClient
      def initialize(contact_list)
        @form = ExtractEmbedForm.new(contact_list.data['embed_code']).call
        super()
      end

      def subscribe(_list_id, params)
        filled_form = FillEmbedForm.new(@form, params.slice(:email, :name)).call
        client.post filled_form.action_url, filled_form.inputs
      end
    end
  end
end
