require 'integration_helper'

feature "MailChimp Integration" do
  before do
    VCR.eject_cassette

    stub_request(:any, /.*api.mailchimp.com.*/).
      to_return(status: 200, body: %({"status":"200"}), headers: {})

    VCR.turned_off do
      service_provider.subscribe("123", "email@example.com", "name", optin)
    end
  end

  let(:identity) {
    Identity.new(provider: "mailchimp",
                 extra: {"metadata" => {}},
                 credentials: {},
                 site: site)
  }

  let(:service_provider) { identity.service_provider}
  let(:site) { create(:site) }

  context "un-specified double-optin parameter" do
    let(:optin) {nil}

    it "sends double-optin" do
      expect(a_request(:post, /.*api.mailchimp.com.*/).
                  with({double_optin: true})
            ).to have_been_made.once
    end
  end

  context "double-optin false" do
    let(:optin) {false}

    it "sends double-optin" do
      expect(a_request(:post, /.*api.mailchimp.com.*/).
                  with({double_optin: false})
            ).to have_been_made.once
    end
  end

end
