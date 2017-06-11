module ServiceProvider::Adapters
  class EmbedCode < FaradayClient
    class EmbedCodeError < StandardError; end

    def initialize(contact_list)
      @contact_list = contact_list
      super()
    end

    def subscribe(_list_id, params)
      filled_form = fill_form(params)
      client.post filled_form.action_url, filled_form.inputs
    end

    def lists
    end

    def tags
    end

    private

    def extract_form
      raise EmbedCodeError, 'Embed code must be provided' if @contact_list.blank? || @contact_list.data['embed_code'].blank?

      ExtractEmbedForm.new(@contact_list.data['embed_code']).call
    end

    def fill_form(params)
      FillEmbedForm.new(extract_form, params.slice(:email, :name)).call
    end
  end
end
