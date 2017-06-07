module ServiceProviders
  module Adapters
    class MyEmma < ServiceProviders::Adapters::EmbedForm
      configure do |config|
        config.requires_embed_code = true
      end

      private

      def fill_form(params)
        FillEmbedForm.new(extract_form, params.slice(:email, :name).merge(ignore: ['prev_member_email'])).call
      end
    end
  end
end
