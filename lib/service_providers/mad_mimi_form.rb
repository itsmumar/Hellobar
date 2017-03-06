module ServiceProviders
  class MadMimiForm < EmbedCodeProvider
    def list_url
      return nil unless list_form
      list_form.attr('action').gsub('subscribe', 'join')
    end

    def list_form
      html.css('#mad_mimi_signup_form').first
    end
  end
end
