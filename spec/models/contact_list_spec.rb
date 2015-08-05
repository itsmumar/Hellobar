require 'spec_helper'

describe ContactList do
  fixtures :all

  let(:site) { sites(:zombo) }
  let(:provider) { 'email' }
  let(:identity) { Identity.new(:site => site, :provider => provider) }
  let(:contact_list) { contact_lists(:zombo).tap{|c| c.identity = identity} }
  let(:service_provider) { contact_list.service_provider }

  before do
    if identity.provider == 'email'
      identity.stub(:service_provider_class).and_return(ServiceProviders::Email)
      ServiceProviders::Email.stub(:settings).and_return({
        oauth: false
      })
      contact_list.stub(:syncable? => true)
      expect(service_provider).to be_a(ServiceProviders::Email)
      service_provider.stub(:batch_subscribe).and_return(nil)
    end

    Hello::DataAPI.stub(:get_contacts).and_return([
      ["test1@hellobar.com", "", 1384807897],
      ["test2@hellobar.com", "", 1384807898]
    ])
  end

  describe "associated identity" do
    it "should use #provider on creation to find the correct identity" do
      list = ContactList.create!(
        :site => sites(:zombo),
        :name => "my list",
        :provider => "mailchimp"
      )

      list.identity.should == identities(:mailchimp)
    end

    it "should use #provider on edit to find the correct identity" do
      list = contact_lists(:zombo)
      list.update_attribute(:identity, identities(:mailchimp))

      list.provider = "constantcontact"
      list.save
      list.identity.should == identities(:constantcontact)
    end

    it "should not be valid if #provider does not match an existing identity" do
      list = contact_lists(:zombo)
      list.provider = "notanesp"
      list.identity = nil

      list.should_not be_valid
      list.errors.messages[:provider].should include("is not valid")
    end

    it "should clear the identity if provider is \"0\"" do
      list = contact_lists(:zombo)
      list.identity.should_not be_blank

      list.update_attributes(:provider => "0")
      list.identity.should be_blank
    end

    it "should notify the old identity when the identity is updated" do
      cl = contact_lists(:zombo2)
      old_identity = cl.identity
      old_identity.should_receive(:contact_lists_updated)
      Identity.stub_chain(:where, :first).and_return(old_identity)
      cl.identity = identities(:constantcontact)
      cl.save
    end

    it "should message the identity when the contact list is destroyed" do
      cl = contact_lists(:zombo2)
      old_identity = cl.identity
      old_identity.should_receive(:contact_lists_updated)
      Identity.stub_chain(:where, :first).and_return(old_identity)
      cl.destroy
    end
  end

  it "should run email sync_all! correctly" do
    contact_list.identity.provider = 'mailchimp'
    contact_list.stub(:oauth?).and_return(true)
    contact_list.save!
    contact_list.stub(:syncable? => true)

    expect(service_provider).to receive(:batch_subscribe)
    contact_list.send :sync_all! # calls #sync_all!
  end

  describe "sync_one!" do
    before do
      contact_list.save!
      contact_list.stub(:syncable? => true)
    end

    context "oauth provider" do
      let(:provider) { 'mailchimp' }
      let(:credentials) { { 'token' => 'asdf' } }
      let(:extra) { { 'metadata' => { 'api_endpoint' => 'asdf' } } }

      before do
        expect_any_instance_of(Identity).to receive(:credentials).and_return(credentials)
        expect_any_instance_of(Identity).to receive(:extra).and_return(extra)
      end

      it "should not raise error" do
        expect(service_provider).to be_oauth
        expect(service_provider).to receive(:subscribe)
        contact_list.sync_one! "email@email.com", "Test Testerson"
      end
    end

    context "embed code provider" do
      let(:provider) { 'mad_mimi' }
      let(:contact_list) { contact_lists(:embed_code).tap{|c| c.identity = identity} }
      let(:service_provider) { contact_list.service_provider }
      let(:double_optin) { ContactList.new.double_optin }

      it "should sync" do
        expect(service_provider).to be_a(ServiceProviders::MadMimi)
        expect(service_provider).to be_embed_code
        expect(service_provider).to receive(:subscribe_params).with("email@email.com", "Test Testerson", double_optin)
        contact_list.sync_one! "email@email.com", "Test Testerson"
      end
    end
  end

  it "should handle invalid JSON correctly" do
    contact_list.update_column :data, "{\"url\":\"http://yoursite.com/goal\",\"collect_names\":0,\"does_not_include\":[\","

    -> { contact_list.reload.data }.should raise_error
  end

  describe "email syncing errors" do
    before do
      Hello::DataAPI.stub(:get_contacts).and_return([:foo, :bar])
      contact_list.stub(:syncable? => true)
      contact_list.stub(:oauth? => true)
    end

    after { contact_list.sync! }

    describe "for mailchimp" do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::MailChimp)
      end

      it "if someone has an invalid list stored, delete the identity and notify them" do
        contact_list.should_receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new("MailChimp API Error: Invalid MailChimp List ID"))
        contact_list.identity.should_receive :destroy_and_notify_user
      end

      it "if someone's token is no longer valid, delete the identity and notify them" do
        contact_list.should_receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new("MailChimp API Error: Invalid Mailchimp API Key"))
        contact_list.identity.should_receive :destroy_and_notify_user
      end

      it "if someone has deleted their account, delete the identity and notify them" do
        contact_list.should_receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new("MailChimp API Error: This account has been deactivated"))
        contact_list.identity.should_receive :destroy_and_notify_user
      end
    end

    describe "for campaign monitor" do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::CampaignMonitor)
      end

      it "if someone has revoked our access, delete the identity and notify them" do
        contact_list.should_receive(:batch_subscribe).and_raise(CreateSend::RevokedOAuthToken.new(Hashie::Mash.new(:Code => 122, :Message => "Revoked OAuth Token")))
        contact_list.identity.should_receive :destroy_and_notify_user
      end
    end

    describe "for aweber" do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::AWeber)
      end

      it "if someone has an invalid list stored, delete the identity and notify them" do
        contact_list.should_receive(:batch_subscribe).and_raise(URI::InvalidURIError.new("bad URI(is not URI?):"))
        contact_list.identity.should_receive :destroy_and_notify_user
      end

      it "if someone's token is no longer valid, or they have deleted their account, delete the identity and notify them" do
        contact_list.should_receive(:batch_subscribe).and_raise(ArgumentError.new("bad value for range"))
        contact_list.identity.should_receive :destroy_and_notify_user
      end
    end

    describe "for constantcontact" do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::ConstantContact)
      end

      it "if someone has an invalid list stored, delete the identity and notify them" do
        response = OpenStruct.new(:code => 404, :body => "404 Resource Not Found")
        contact_list.should_receive(:batch_subscribe).and_raise(RestClient::ResourceNotFound.new(response))
        contact_list.identity.should_receive :destroy_and_notify_user
      end
    end
  end

  describe "#subscribers" do
    it "gets subscribers from the data API" do
      Hello::DataAPI.stub(:get_contacts => [["person@gmail.com", "Per Son", 123456789]])
      contact_list.subscribers.should == [{:email => "person@gmail.com", :name => "Per Son", :subscribed_at => Time.at(123456789)}]
    end

    it "defaults to [] if data API returns nil" do
      Hello::DataAPI.stub(:get_contacts => nil)
      contact_list.subscribers.should == []
    end
  end

  describe "#subscriber_statuses" do
    it "returns empty hash if service provider does not retreive statuses" do
      service_provider.stub(:respond_to?).with(:subscriber_statuses).and_return false
      contact_list.subscriber_statuses([{email: "test"}]).should == {}
    end

    it "returns a hash with the status as returned by the service provider" do
      subscribers = [{email: "test@test.com"}, {email: "test2@test.com"}]
      result = { "test@test.com" => "pending", "test2@test.com" => "subscribed" }
      service_provider.should_receive(:subscriber_statuses)\
        .with(contact_list.data["remote_id"], ["test@test.com", "test2@test.com"]).and_return(result)
      contact_list.subscriber_statuses(subscribers).should == result
    end
  end

  describe "#num_subscribers" do
    it "gets number of subscribers from the data API" do
      Hello::DataAPI.stub(:contact_list_totals => {contact_list.id.to_s => 5})
      contact_list.num_subscribers.should == 5
    end

    it "defaults to 0 if data API returns nil" do
      Hello::DataAPI.stub(:contact_list_totals => nil)
      contact_list.num_subscribers.should == 0
    end
  end

  describe "#data" do
    it "drops nil values in data" do
      contact_list.data = { "remote_name" => "", "remote_id" => 1}
      contact_list.identity = nil
      contact_list.stub(:sync_all!).and_return(true)
      contact_list.save
      contact_list.data['remote_name'].should be_nil
    end
  end
end

describe ContactList, "embed code" do
  fixtures :all

  subject { contact_lists(:embed_code) }

  before { subject.data['embed_code'] = embed_code }

  context "invalid" do
    let(:embed_code) { "asdf" }
    its(:data) { should == { 'embed_code' => 'asdf' } }
    its(:embed_code_valid?) { should == false }
  end

  context "invalid" do
    let(:embed_code) { "<<asdfasdf>>>" }
    its(:embed_code_valid?) { should == false }
  end

  context "invalid" do
    let(:embed_code) { "<from></from>" }
    its(:embed_code_valid?) { should == false }
  end

  context "valid" do
    let(:embed_code) { "<form></form>" }
    its(:embed_code_valid?) { should == true }
  end
end

describe ContactList, "sync!" do
  fixtures :all

  subject { contact_lists(:embed_code) }

  context "embed_code changed" do
    after { subject.update_attribute :data, { "embed_code" => "new embed code" } }
    it { should receive(:sync) }
    it { should receive(:sync_all!) } # this one via `delay`
  end
end
