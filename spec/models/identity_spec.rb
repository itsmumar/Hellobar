require 'spec_helper'

describe Identity do
  fixtures :all

  before do
    @site = sites(:zombo)
    @identity = identities(:mailchimp)
  end

  describe "find_or_initialize_by_site_id_and_provider" do
    it "initializes a new identity if none exists for a site and provider combination" do
      identity = Identity.find_or_initialize_by_site_id_and_provider(@site.id, 'aweber')

      identity.site_id.should == @site.id
      identity.provider.should == 'aweber'
      identity.id.should == nil
    end

    it "loads an existing identity if one exists for a site and provider combination" do
      returned_identity = Identity.find_or_initialize_by_site_id_and_provider(@identity.site_id, @identity.provider)

      returned_identity.should == @identity
    end

    it "uses the provider name to get the API client class" do
      Gibbon::API.stubs(:new => double("gibbon"))

      identity = Identity.new(:provider => "mailchimp", :extra => {"metadata" => {}}, :credentials => {})
      identity.service_provider.should be_an_instance_of ServiceProviders::MailChimp

      identity = Identity.new(:provider => "aweber", :credentials => {})
      identity.service_provider.should be_an_instance_of ServiceProviders::AWeber
    end

    describe "destroy_and_notify_user" do
      it "should email the user that there was a problem syncing their identity" do
        MailerGateway.should_receive(:send_email) do |*args|
          args[0].should == "Integration Sync Error"
          args[1].should == @identity.site.owner.email
          args[2][:link].should =~ /http\S+sites\S+#{@identity.site_id}/
          args[2][:integration_name].should == "MailChimp"
        end

        @identity.destroy_and_notify_user
      end
    end
  end

  describe "embed code service provider" do
    let(:id) { @site.identities.new }

    it "works with Mad Mimi" do
      id.provider = 'mad_mimi'
      id.embed_code = embed_code_file_for 'mad_mimi'

      id.service_provider.list_url.should == 'https://madmimi.com/signups/join/103242'
      id.service_provider.action_url.should == 'https://madmimi.com/signups/subscribe/103242'
      id.service_provider.list_id.should == '103242'

      id.service_provider.params.any? {|item| item[:name] == 'signup[email]' }.should == true
      id.service_provider.email_param.should == 'signup[email]'
      id.service_provider.name_param.should == 'signup[name]'
      id.service_provider.required_params.should be_empty
    end

    it "works with GetResponse html mode" do
      id.provider = 'get_response'
      id.embed_code = embed_code_file_for 'get_response'

      id.service_provider.list_url.should == 'https://app.getresponse.com/site/colin_240991/webform.html?u=G91K&wid=1324102'
      id.service_provider.action_url.should == 'https://app.getresponse.com/add_contact_webform.html?u=G91K' # same for getresponse
      id.service_provider.email_param.should == 'email'
      id.service_provider.name_param.should == 'name'
    end

    it "works with GetResponse JS mode" do
      id.provider = 'get_response'
      id.embed_code = embed_code_file_for 'get_response_js'

      id.service_provider.class.should == ServiceProviders::GetResponse

      id.service_provider.list_url.should == 'https://app.getresponse.com/site/colin_240991/webform.html?u=G91K&wid=2350002'
      id.service_provider.action_url.should match /https?:\/\/app\.getresponse\.com\/add_contact_webform\.html\?u=G91K/ # same for getresponse
      id.service_provider.email_param.should == 'email'
      id.service_provider.name_param.should == 'name'
    end

    it "works with VerticalResponse" do
      id.provider = 'vertical_response'
      id.embed_code = embed_code_file_for 'vertical_response'

      id.service_provider.email_param.should == 'email_address'
      id.service_provider.name_params.should == ['first_name', 'last_name']
      id.service_provider.required_params.should be_empty
    end

    it "works with iContact automatic" do
      id.provider = 'icontact'
      id.embed_code = embed_code_file_for 'icontact'

      id.service_provider.class.should == ServiceProviders::IContact

      id.service_provider.list_url.should == nil
      id.service_provider.action_url.should == 'http://app.icontact.com/icp/signup.php'
      id.service_provider.email_param.should == 'fields_email'
      id.service_provider.name_params.should == ['fields_fname', 'fields_lname']
      id.service_provider.required_params.should == {
        'redirect' => 'http://www.hellobar.com/emailsignup/icontact/success',
        'errorredirect' => 'http://www.hellobar.com/emailsignup/icontact/error',
        'listid' => '10108',
        'specialid:10108' => 'O2D3',
        'clientid' => '1450422',
        'formid' => '564',
        'reallistid' => '1',
        'doubleopt' => '0',
        'Submit' => 'Submit'
      }
      -> { id.service_provider.name_param}.should raise_error ServiceProviders::EmbedCodeProvider::FirstAndLastNameRequired
    end

    it "works with iContact manual" do
      id.provider = 'icontact'
      id.embed_code = embed_code_file_for 'icontact_manual'

      id.service_provider.class.should == ServiceProviders::IContact

      id.service_provider.list_url.should == nil
      id.service_provider.action_url.should == 'https://app.icontact.com/icp/signup.php'
      id.service_provider.email_param.should == 'fields_email'
      id.service_provider.name_params.should == ['fields_fname', 'fields_lname']
      id.service_provider.required_params.should == {
        'redirect' => 'http://www.hellobar.com/emailsignup/icontact/success',
        'errorredirect' => 'http://www.hellobar.com/emailsignup/icontact/error',
        'listid' => '10108',
        'specialid:10108' => 'O2D3',
        'clientid' => '1450422',
        'formid' => '564',
        'reallistid' => '1',
        'doubleopt' => '0',
        'Submit' => 'Submit'
      }
      -> { id.service_provider.name_param}.should raise_error ServiceProviders::EmbedCodeProvider::FirstAndLastNameRequired
    end

    %w(my_emma my_emma_js my_emma_iframe my_emma_popup).each do |file|
      it "works with My Emma #{file}".strip do
        id.provider = 'my_emma'
        id.embed_code = embed_code_file_for file

        id.service_provider.list_url.should == 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
        id.service_provider.action_url.should == id.service_provider.list_url # same for my emma
        id.service_provider.email_param.should == 'email'
        id.service_provider.required_params.keys.should include 'prev_member_email'
      end
    end

    it 'replaces curly quotes' do
      id.provider = 'get_response'
      id.embed_code         = "<form action=”https://app.getresponse.com/add_subscriber.html” accept-charset=”utf-8” method=”post”>"
      id.save!
      id.reload
      id.embed_code.should == '<form action="https://app.getresponse.com/add_subscriber.html" accept-charset="utf-8" method="post">'
    end
  end
end
