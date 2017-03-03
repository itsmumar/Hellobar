require 'spec_helper'

describe Identity do
  fixtures :all

  before do
    @site = sites(:zombo)
    @identity = identities(:mailchimp)
  end

  describe 'initialization' do
    it 'initializes a new identity if none exists for a site and provider combination' do
      identity = Identity.where(site_id: @site.id, provider: 'aweber').first_or_initialize

      identity.site_id.should == @site.id
      identity.provider.should == 'aweber'
      identity.id.should == nil
    end

    it 'loads an existing identity if one exists for a site and provider combination' do
      returned_identity = Identity.where(site_id: @identity.site_id, provider: @identity.provider).first_or_initialize

      returned_identity.should == @identity
    end

    it 'uses the provider name to get the API client class' do
      Gibbon::Request.stubs(:new => double('gibbon'))

      identity = Identity.new(:provider => 'mailchimp', :extra => {'metadata' => {}}, :credentials => {})
      identity.service_provider.should be_an_instance_of ServiceProviders::MailChimp

      identity = Identity.new(:provider => 'aweber', :credentials => {})
      identity.service_provider.should be_an_instance_of ServiceProviders::AWeber
    end

    describe 'service provider' do
      it 'should call destroy_and_notify_user when it encounters an error' do
        Gibbon::Request.stubs(:new => double('gibbon'))

        identity = Identity.new(:provider => 'mailchimp', :extra => {'metadata' => {}}, :credentials => {})
        ServiceProviders::MailChimp.should_receive(:new).and_raise(Gibbon::MailChimpError)
        identity.should_receive(:destroy_and_notify_user)
        identity.service_provider.should be_nil
      end
    end

    describe 'destroy_and_notify_user' do
      it 'should email the user that there was a problem syncing their identity' do
        MailerGateway.should_receive(:send_email) do |*args|
          args[0].should == 'Integration Sync Error'
          args[1].should == @identity.site.owners.first.email
          args[2][:link].should =~ /http\S+sites\S+#{@identity.site_id}/
          args[2][:integration_name].should == 'MailChimp'
        end

        @identity.destroy_and_notify_user
      end
    end
  end

  describe 'contact lists updated' do
    context 'still has referencing contact lists' do
      it 'should do nothing' do
        identity = contact_lists(:zombo_contacts).identity
        identity.contact_lists_updated
        identity.destroyed?.should be_false
      end
    end

    context 'has no referencing contact lists' do
      it 'should do nothing' do
        identity = Identity.create(:provider => 'aweber', :credentials => {}, :site => sites(:zombo))
        identity.contact_lists_updated
        identity.destroyed?.should be_true
      end
    end
  end

  describe 'embed code service provider' do
    let(:contact_list) do
      contact_lists(:embed_code).tap {|c| c.identity = nil }
    end
    let(:file_name) { (file rescue provider) }

    let(:service_provider) do
      contact_list.provider = provider
      contact_list.data['embed_code'] = embed_code_file_for(file_name)
      contact_list.send(:set_identity)
      contact_list.service_provider
    end

    context 'madmimi form' do
      let(:provider) { 'mad_mimi_form' }
      it 'works' do
        service_provider.list_url.should == 'https://madmimi.com/signups/join/103242'
        service_provider.action_url.should == 'https://madmimi.com/signups/subscribe/103242'
        service_provider.list_id.should == '103242'

        service_provider.params.any? {|item| item[:name] == 'signup[email]' }.should == true
        service_provider.email_param.should == 'signup[email]'
        service_provider.name_params.should be_empty
        service_provider.required_params.should be_empty
      end
    end

    context 'getresponse html mode' do
      let(:provider) { 'get_response' }
      it 'works' do
        service_provider.list_url.should == 'https://app.getresponse.com/site/colin_240991/webform.html?u=G91K&wid=1324102'
        service_provider.action_url.should == 'https://app.getresponse.com/add_contact_webform.html?u=G91K' # same for getresponse
        service_provider.email_param.should == 'email'
        service_provider.name_param.should == 'name'
      end
    end

    context 'getresponse JS mode' do
      let(:provider) { 'get_response' }
      let(:file) { 'get_response_js' }
      it 'works' do
        service_provider.class.should == ServiceProviders::GetResponse

        service_provider.list_url.should == 'https://app.getresponse.com/site/colin_240991/webform.html?u=G91K&wid=2350002'
        service_provider.action_url.should match /https?:\/\/app\.getresponse\.com\/add_contact_webform\.html\?u=G91K/ # same for getresponse
        service_provider.email_param.should == 'email'
        service_provider.name_param.should == 'name'
      end
    end

    context 'VerticalResponse' do
      let(:provider) { 'vertical_response' }
      it 'works' do
        service_provider.email_param.should == 'email_address'
        service_provider.name_params.should == %w(first_name last_name)
        service_provider.required_params.should be_empty
      end
    end

    context 'iContact automatic' do
      let(:provider) { 'icontact' }
      it 'works' do
        service_provider.class.should == ServiceProviders::IContact

        service_provider.list_url.should == nil
        service_provider.action_url.should == 'http://app.icontact.com/icp/signup.php'
        service_provider.email_param.should == 'fields_email'
        service_provider.name_params.should == %w(fields_fname fields_lname)
        service_provider.required_params.should == {
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
        -> { service_provider.name_param}.should raise_error ServiceProviders::EmbedCodeProvider::FirstAndLastNameRequired
      end
    end

    context 'iContact automatic' do
      let(:provider) { 'icontact' }
      let(:file) { 'icontact_manual' }
      it 'works' do
        service_provider.class.should == ServiceProviders::IContact

        service_provider.list_url.should == nil
        service_provider.action_url.should == 'https://app.icontact.com/icp/signup.php'
        service_provider.email_param.should == 'fields_email'
        service_provider.name_params.should == %w(fields_fname fields_lname)
        service_provider.required_params.should == {
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
        -> { service_provider.name_param}.should raise_error ServiceProviders::EmbedCodeProvider::FirstAndLastNameRequired
      end
    end

    context 'my emma' do
      let(:provider) { 'my_emma' }

      %w(my_emma my_emma_js my_emma_iframe my_emma_popup).each do |file|
        let(:file) { file }
        it "works with My Emma #{file}".strip do
          service_provider.list_url.should == 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
          service_provider.action_url.should == service_provider.list_url # same for my emma
          service_provider.email_param.should == 'email'
          service_provider.required_params.keys.should include 'prev_member_email'
        end
      end
    end
  end

  describe '#embed_code=' do
    it 'should raise error' do
      expect { @identity.embed_code = 'asdf' }.to raise_error NoMethodError
    end
  end
end
