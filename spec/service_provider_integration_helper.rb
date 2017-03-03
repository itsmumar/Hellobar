shared_context 'service provider request setup' do
  before do
    VCR.eject_cassette

    stub_request(:any, Regexp.new(".*#{api_domain}.*"))
      .to_return(status: 200, body: %({"status":"200"}), headers: {})

    VCR.turned_off do
      service_provider.subscribe('123', email, name, optin)
    end
  end

  let(:identity) do
    Identity.new(
      provider: provider,
      extra: { 'metadata' => {} },
      credentials: { 'token' => 'foobar-token' },
      site: site
    )
  end

  let(:url)              { "http://#{api_domain}" }
  let(:email)            { 'email@example.com' }
  let(:name)             { 'JohnDoe' }
  let(:optin)            { true }
  let(:service_provider) { identity.service_provider }
  let(:site)             { create(:site) }
end

def open_provider_form(user, pname)
  site = user.sites.create(url: random_uniq_url)
  contact_list = create(:contact_list, site: site)

  visit site_contact_list_path(site, contact_list)

  page.find('#edit-contact-list').click
  page.find('a', text: 'Nevermind, I want to view all tools').click
  page.find(".#{pname}-provider").click
end
