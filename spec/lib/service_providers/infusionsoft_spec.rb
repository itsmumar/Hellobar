require "spec_helper"

describe ServiceProviders::Infusionsoft do
  let(:identity) { Identity.new(:provider => "infusionsoft", :api_key => "test-api-key", :extra => {app_url: "test1.infusionsoft.com"}) }
  let(:service_provider) { identity.service_provider }
  let(:contact_list) { ContactList.new }

  before do
    allow(Infusionsoft).to receive(:contact_add_with_dup_check) { 1 }
  end

  describe "#lists" do
    it "should make a call to Infusionsoft for their tags" do
      expect(Infusionsoft).to receive(:data_query) { [] }
      service_provider.lists
    end
  end

  describe "#subscribe" do
    it "should call contact_add_with_dup_check" do
      data = { Email: "test@test.com" }
      service_provider.instance_variable_set(:@contact_list, contact_list)
      expect(Infusionsoft).to receive(:contact_add_with_dup_check).with(data, :Email)
      service_provider.subscribe(nil, "test@test.com")
    end

    it "should tag the user with all of the tags when present" do
      contact_list.data = { "tags" => %w{ 1 2 3 } }
      service_provider.instance_variable_set(:@contact_list, contact_list)

      expect(Infusionsoft).to receive(:contact_add_to_group).exactly(3).times { nil }

      service_provider.subscribe(nil, "test@test.com")
    end

    it "should NOT tag the user when no tags are present" do
      expect(Infusionsoft).to_not receive(:contact_add_to_group)
      service_provider.instance_variable_set(:@contact_list, contact_list)

      service_provider.subscribe(nil, "test@test.com")
    end
  end
end
