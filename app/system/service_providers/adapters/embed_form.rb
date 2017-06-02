module ServiceProviders
  module Adapters
    class EmbedForm < FaradayClient
      def initialize(contact_list)
        @form = ExtractEmbedForm.new(contact_list.data['embed_code']).call
        super()
      end

      def subscribe(_list_id, params)
        filled_form = fill_form(params)
        client.post filled_form.action_url, filled_form.inputs
      end

      private

      def fill_form(params)
        FillEmbedForm.new(@form, params.slice(:email, :name)).call
      end
    end
  end
end
