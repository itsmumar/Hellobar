require "spec_helper"

describe ServiceProviders::ActiveCampaign do
  let(:identity) { Identity.new(:provider => "active_campaign",
                                :api_key => "dea2f200e17b9a3205f3353030b7d8ad55852aa3ccec6d7c4120482c8e8feb5fd527cff3",
                                :extra => { "app_url" => "hellobar.api-us1.com" }) }
  let(:service_provider) { identity.service_provider }
  let(:contact_list) { ContactList.new }
  let(:cassette_base) { 'service_providers/active_campaign' }
  let(:client) { service_provider.instance_variable_get(:@client) }

  # before do
  #   allow(Infusionsoft).to receive(:contact_add_with_dup_check) { 1 }
  # end

  describe "#lists" do
    it "should make a call to ActiveCampaign for lists" do
      VCR.use_cassette(cassette_base + '/lists') do
        expect(service_provider.lists.count).to eq(2)
      end
    end
  end

  describe "#subscribe" do
    context "NOT having `list_id`" do
      let(:email) { "test@test.com" }
      before(:each) do
        @data = { email: email }
        service_provider.instance_variable_set(:@contact_list, contact_list)
      end

      it "should call contact_sync and add new contact" do
        # expect(client).to receive(:contact_sync).with(@data)

        VCR.use_cassette(cassette_base + '/contact_sync') do
          response = service_provider.subscribe(nil, email)
          expect(response['result_message']).to eq('Contact added')
        end
      end

      it "should add email and name" do
        VCR.use_cassette(cassette_base + '/contact_sync') do
          service_provider.subscribe(nil, email, "Test User")

          name_attrs = { :first_name => "Test", :last_name => "User" }
          # expect(client).to receive(:contact_sync).with(@data.merge(name_attrs))
        end
      end
    end

    # context "having `list_id`" do
    #   it "should add user to the list, when `list_id` is present" do
    #     contact_list.data = { "remote_id" => 1 }
    #     service_provider.instance_variable_set(:@contact_list, contact_list)
    #
    #     expect(ActiveCampaign).to receive(:contact_sync).exactly(3).times { nil }
    #
    #     service_provider.subscribe(nil, "test@test.com")
    #   end
    #
    #   it "should add user to global list when `list_id` is unavailable" do
    #     expect(ActiveCampaign).to_not receive(:contact_sync)
    #     service_provider.instance_variable_set(:@contact_list, contact_list)
    #
    #     service_provider.subscribe(nil, "test@test.com")
    #   end
    # end
  end
end
