require 'spec_helper'

describe ContactList do
  fixtures :all

  let(:site) { sites(:zombo) }
  let(:identity) { Identity.new(:site => site) }
  let(:contact_list) { contact_lists(:zombo).tap{|c| c.identity = identity} }

  before do
    @mock_service_provider = double("service provider", :lists => [{"id" => "1"}])
    contact_list.stub(:service_provider).and_return(@mock_service_provider)

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
  end

  it "should run email integrable sync correctly" do
    contact_list.identity.provider = 'mailchimp'
    contact_list.save!
    contact_list.last_synced_at.should be_nil
    contact_list.stub(:syncable? => true)

    @mock_service_provider.should_receive(:batch_subscribe)

    contact_list.send :subscribe_all_emails_to_list!

    contact_list.last_synced_at.should_not be_nil
  end

  it "should queue all jobs when running sync_all!" do
    mock_list = double("contact list", :syncable? => true)
    mock_list.should_receive(:sync!)
    ContactList.stub(:all).and_return([mock_list])

    ContactList.sync_all!
  end

  it "should handle invalid JSON correctly" do
    contact_list.update_column :data, "{\"url\":\"http://yoursite.com/goal\",\"collect_names\":0,\"exclude_urls\":[\","

    -> { contact_list.reload.data }.should raise_error
  end

  describe "email syncing errors" do
    before do
      Hello::DataAPI.stub(:get_contacts).and_return([:foo, :bar])
    end

    describe "for mailchimp" do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::MailChimp)
      end

      it "if someone has an invalid list stored, delete the identity and notify them" do
        @mock_service_provider.should_receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new("MailChimp API Error: Invalid MailChimp List ID"))
        contact_list.identity.should_receive :destroy_and_notify_user

        contact_list.send :subscribe_all_emails_to_list!
      end

      it "if someone's token is no longer valid, delete the identity and notify them" do
        @mock_service_provider.should_receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new("MailChimp API Error: Invalid Mailchimp API Key"))
        contact_list.identity.should_receive :destroy_and_notify_user

        contact_list.send :subscribe_all_emails_to_list!
      end

      it "if someone has deleted their account, delete the identity and notify them" do
        @mock_service_provider.should_receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new("MailChimp API Error: This account has been deactivated"))
        contact_list.identity.should_receive :destroy_and_notify_user

        contact_list.send :subscribe_all_emails_to_list!
      end
    end

    describe "for campaign monitor" do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::CampaignMonitor)
      end

      it "if someone has revoked our access, delete the identity and notify them" do
        @mock_service_provider.should_receive(:batch_subscribe).and_raise(CreateSend::RevokedOAuthToken.new(Hashie::Mash.new(:Code => 122, :Message => "Revoked OAuth Token")))
        contact_list.identity.should_receive :destroy_and_notify_user

        contact_list.send :subscribe_all_emails_to_list!
      end
    end

    describe "for aweber" do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::AWeber)
      end

      it "if someone has an invalid list stored, delete the identity and notify them" do
        @mock_service_provider.should_receive(:batch_subscribe).and_raise(URI::InvalidURIError.new("bad URI(is not URI?):"))
        contact_list.identity.should_receive :destroy_and_notify_user

        contact_list.send :subscribe_all_emails_to_list!
      end

      it "if someone's token is no longer valid, or they have deleted their account, delete the identity and notify them" do
        @mock_service_provider.should_receive(:batch_subscribe).and_raise(ArgumentError.new("bad value for range"))
        contact_list.identity.should_receive :destroy_and_notify_user

        contact_list.send :subscribe_all_emails_to_list!
      end
    end

    describe "for constantcontact" do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::ConstantContact)
      end

      it "if someone has an invalid list stored, delete the identity and notify them" do
        response = OpenStruct.new(:code => 404, :body => "404 Resource Not Found")
        @mock_service_provider.should_receive(:batch_subscribe).and_raise(RestClient::ResourceNotFound.new(response))
        contact_list.identity.should_receive :destroy_and_notify_user

        contact_list.send :subscribe_all_emails_to_list!
      end
    end
  end

  describe "#subscribers" do
    it "gets subscribers from the data API" do
      Hello::DataAPI.stub(:get_contacts => [["person@gmail.com", "Per Son"]])
      contact_list.subscribers.should == [{:email => "person@gmail.com", :name => "Per Son"}]
    end

    it "defaults to [] if data API returns nil" do
      Hello::DataAPI.stub(:get_contacts => nil)
      contact_list.subscribers.should == []
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
      contact_list.save
      contact_list.data['remote_name'].should be_nil
    end
  end
end

describe ContactList, "embed code" do
  fixtures :contact_lists, :identities, :sites

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
