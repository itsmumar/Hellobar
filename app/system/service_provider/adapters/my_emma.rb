module ServiceProvider::Adapters
  class MyEmma < EmbedCode
    configure do |config|
      config.requires_embed_code = true
    end

    private

    def fill_form(params)
      FillEmbedForm.new(extract_form, params.slice(:email, :name).merge(ignore: ['prev_member_email'])).call
    end
  end
end
