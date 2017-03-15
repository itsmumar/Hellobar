module ServiceProviders
  class MyEmma < EmbedCodeProvider
    def email_param
      field = list_form.css('input[type="email"], input[type="text"]').find do |f|
        f[:name].include? 'email'
      end

      field[:name]
    end

    def html
      html = super
      return html unless html && (a = html.css('body > a[onclick]').first)

      # we're looking at the popup one
      remote_html = HTTParty.get a.attr('href')
      @html = Nokogiri::HTML(remote_html)
    end

    def get_reference_object html
      item = super
      if !item || !item.attr('src') || item.attr('src').include?('tts_signup')
        html.css('a').first
      else
        item
      end
    end
  end
end
