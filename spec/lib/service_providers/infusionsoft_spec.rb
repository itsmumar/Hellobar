require "spec_helper"

describe ServiceProviders::Infusionsoft do
  let(:identity) { Identity.new(:provider => "infusionsoft", :api_key => "test-api-key", :extra => {app_url: "test1.infusionsoft.com"}) }
  let(:service_provider) { identity.service_provider}

  describe "#lists" do
    it "should be an empty list" do
      expect(service_provider.lists).to be_empty
    end
  end

  describe "#subscribe" do
    it "should call contact_add_with_dup_check" do
      Infusionsoft.stub(:contact_add_with_dup_check) { 1 }

      allow_any_instance_of(Infusionsoft).to receive(:contact_add_with_dup_check).and_return(1)

      service_provider.subscribe(nil, "test@test.com")
    end
  end
end
