require 'integration_helper'
require 'service_provider_integration_helper'

feature "MailChimp Integration" do
  include_context "service provider request setup"

  let(:provider)         { "mailchimp" }
  let(:api_domain)       { "api.mailchimp.com" }

  context "un-specified double-optin parameter" do
    it "sends double-optin" do
      expect(a_request(:post, /.*api.mailchimp.com.*/).
               with do |req|
                 params = JSON.parse req.body
                 params["double_optin"] == true
               end
            ).to have_been_made.once
    end
  end

  context "double-optin false" do
    let(:optin) {false}

    it "sends double-optin" do
      expect(a_request(:post, /.*api.mailchimp.com.*/).
               with do |req|
                 params = JSON.parse req.body
                 params["double_optin"] == false
               end
            ).to have_been_made.once
    end
  end

end
