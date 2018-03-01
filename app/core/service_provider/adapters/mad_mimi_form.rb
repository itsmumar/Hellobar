module ServiceProvider::Adapters
  class MadMimiForm < EmbedCode
    configure do |config|
      config.requires_embed_code = true
      config.hidden = true
    end

    private

    def fill_form(params)
      FillEmbedForm.new(extract_form, params.slice(:email, :name).merge(delete: ['beacon'])).call
    end
  end
end
