require "spec_helper"

describe ServiceProviders::AWeber do
  let(:identity) { Identity.new(:provider => "aweber", :extra => {"metadata" => {}}, :credentials => {}) }
  let(:service_provider) { identity.service_provider}
  let(:client) { service_provider.instance_variable_get(:@client) }

  describe "subscribe" do
    it "catches AWeber::CreationError errors" do
      allow(client).to receive(:account).and_raise(AWeber::CreationError)
      expect {
        service_provider.subscribe("123", "abc")
      }.not_to raise_error
    end
  end
end
