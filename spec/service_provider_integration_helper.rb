shared_context "service provider request setup" do
  before do
    VCR.eject_cassette

    stub_request(:any, Regexp.new(".*#{api_domain}.*")).
      to_return(status: 200, body: %({"status":"200"}), headers: {})

    VCR.turned_off do
      service_provider.subscribe("123", email, name, optin)
    end
  end

  let(:identity) {
    Identity.new(provider: provider,
                 extra: {"metadata" => {}},
                 credentials: {'token' => 'foobar-token'},
                 site: site)
  }

  let(:url)              { "http://#{api_domain}" }
  let(:email)            { "email@example.com" }
  let(:name)             { "JohnDoe" }
  let(:optin)            { true }
  let(:service_provider) { identity.service_provider }
  let(:site)             { create(:site) }

end
