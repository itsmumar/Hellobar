module ServiceProviders
  module Adapters
    class MyEmma < EmbedForm
      register :my_emma

      private

      def fill_form(params)
        FillEmbedForm.new(@form, params.slice(:email, :name).merge(ignore: ['prev_member_email'])).call
      end
    end
  end
end
