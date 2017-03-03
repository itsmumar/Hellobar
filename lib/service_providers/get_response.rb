module ServiceProviders
  class GetResponse < EmbedCodeProvider
    def extract_html_from_script html
      html.match(/unescape\('(<(?:body|div).+>)'\)/)
    end

    def campaign_id
      span = html.css('span[name*="campaign_name"]').try(:first)
      if span
        url = span.try(:attr, 'name')
        url = URI.decode(url)
        query_params = CGI::parse URI::parse(url).query
        query_params['campaign_name'][0]
      end
    end

    def webform_id
      html.css('input[name="webform_id"]').try(:first).try(:attr, 'value')
    end

    def list_url
      list_url = super
      list_url.gsub(/https?/, 'https')
              .gsub('add_contact_webform.html', "site/#{campaign_id}/webform.html") + "&wid=#{webform_id}"
    end

    def subscribe_params(email, name, double_optin = true)
      super(email, name, double_optin).merge(
        'type' => 'ajax'
      )
    end
  end
end
