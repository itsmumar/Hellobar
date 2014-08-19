module ServiceProviders
  class IContact < EmbedCodeProvider
    provider_key :icontact

    def list_url
      nil
    end

    def embed_code_valid?
      super || html.css('script').first.try(:attr, 'src') == "https://app.icontact.com/icp/signup.php"
    end
  end
end
