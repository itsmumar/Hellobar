require 'spec_helper'

describe Identity do
  let(:site) { create(:site, :with_user) }
  let(:identity) { create(:identity, :mailchimp, site: site) }

  describe 'initialization' do
    it 'initializes a new identity if none exists for a site and provider combination' do
      identity = Identity.where(site_id: site.id, provider: 'aweber').first_or_initialize

      expect(identity.site_id).to eq(site.id)
      expect(identity.provider).to eq('aweber')
      expect(identity.id).to be_nil
    end

    it 'loads an existing identity if one exists for a site and provider combination' do
      returned_identity = Identity.where(site_id: identity.site_id, provider: identity.provider).first_or_initialize

      expect(returned_identity).to eq(identity)
    end

    it 'uses the provider name to get the API client class' do
      allow(Gibbon::Request).to receive(:new).and_return(double('gibbon'))

      identity = Identity.new(provider: 'mailchimp', extra: { 'metadata' => {} }, credentials: {})
      expect(identity.service_provider).to be_an_instance_of ServiceProviders::MailChimp

      identity = Identity.new(provider: 'aweber', credentials: {})
      expect(identity.service_provider).to be_an_instance_of ServiceProviders::AWeber
    end

    describe 'service provider' do
      it 'should call destroy_and_notify_user when it encounters an error' do
        allow(Gibbon::Request).to receive(:new).and_return(double('gibbon'))

        identity = Identity.new(provider: 'mailchimp', extra: { 'metadata' => {} }, credentials: {})
        expect(ServiceProviders::MailChimp).to receive(:new).and_raise(Gibbon::MailChimpError)
        expect(identity).to receive(:destroy_and_notify_user)
        expect(identity.service_provider).to be_nil
      end
    end

    describe 'destroy_and_notify_user' do
      it 'should email the user that there was a problem syncing their identity' do
        expect(MailerGateway).to receive(:send_email) do |*args|
          expect(args[0]).to eq('Integration Sync Error')
          expect(args[1]).to eq(identity.site.owners.first.email)
          expect(args[2][:link]).to match(/http\S+sites\S+#{identity.site_id}/)
          expect(args[2][:integration_name]).to eq('MailChimp')
        end

        identity.destroy_and_notify_user
      end
    end
  end

  describe 'contact lists updated' do
    context 'still has referencing contact lists' do
      it 'should do nothing' do
        identity = create(:contact_list, :mailchimp).identity
        identity.contact_lists_updated
        expect(identity.destroyed?).to be_falsey
      end
    end

    context 'has no referencing contact lists' do
      it 'should do nothing' do
        identity = Identity.create(provider: 'aweber', credentials: {}, site: site)
        identity.contact_lists_updated
        expect(identity.destroyed?).to be_truthy
      end
    end
  end

  describe 'embed code service provider' do
    let(:contact_list) { create(:contact_list, :embed_code, identity: nil) }
    let(:file) {}
    let(:provider) {}
    let(:file_name) { file || provider }

    let(:service_provider) do
      contact_list.provider = provider
      contact_list.data['embed_code'] = embed_code_file_for(file_name)
      contact_list.send(:set_identity)
      contact_list.service_provider
    end

    context 'madmimi form' do
      let(:provider) { 'mad_mimi_form' }
      it 'works' do
        expect(service_provider.list_url).to eq('https://madmimi.com/signups/join/103242')
        expect(service_provider.action_url).to eq('https://madmimi.com/signups/subscribe/103242')
        expect(service_provider.list_id).to eq('103242')

        expect(service_provider.params.any? { |item| item[:name] == 'signup[email]' }).to eq(true)
        expect(service_provider.email_param).to eq('signup[email]')
        expect(service_provider.name_params).to be_empty
        expect(service_provider.required_params).to be_empty
      end
    end

    context 'getresponse html mode' do
      let(:provider) { 'get_response' }
      it 'works' do
        expect(service_provider.list_url).to eq('https://app.getresponse.com/site/colin_240991/webform.html?u=G91K&wid=1324102')
        expect(service_provider.action_url).to eq('https://app.getresponse.com/add_contact_webform.html?u=G91K') # same for getresponse
        expect(service_provider.email_param).to eq('email')
        expect(service_provider.name_param).to eq('name')
      end
    end

    context 'getresponse JS mode' do
      let(:provider) { 'get_response' }
      let(:file) { 'get_response_js' }
      it 'works' do
        expect(service_provider.class).to eq(ServiceProviders::GetResponse)

        expect(service_provider.list_url).to eq('https://app.getresponse.com/site/colin_240991/webform.html?u=G91K&wid=2350002')
        expect(service_provider.action_url).to match(/https?:\/\/app\.getresponse\.com\/add_contact_webform\.html\?u=G91K/) # same for getresponse
        expect(service_provider.email_param).to eq('email')
        expect(service_provider.name_param).to eq('name')
      end
    end

    context 'VerticalResponse' do
      let(:provider) { 'vertical_response' }
      it 'works' do
        expect(service_provider.email_param).to eq('email_address')
        expect(service_provider.name_params).to eq(['first_name', 'last_name'])
        expect(service_provider.required_params).to be_empty
      end
    end

    context 'iContact automatic' do
      let(:provider) { 'icontact' }
      it 'works' do
        expect(service_provider.class).to eq(ServiceProviders::IContact)

        expect(service_provider.list_url).to be_nil
        expect(service_provider.action_url).to eq('http://app.icontact.com/icp/signup.php')
        expect(service_provider.email_param).to eq('fields_email')
        expect(service_provider.name_params).to eq(['fields_fname', 'fields_lname'])
        expect(service_provider.required_params).to eq(
          'redirect' => 'http://www.hellobar.com/emailsignup/icontact/success',
          'errorredirect' => 'http://www.hellobar.com/emailsignup/icontact/error',
          'listid' => '10108',
          'specialid:10108' => 'O2D3',
          'clientid' => '1450422',
          'formid' => '564',
          'reallistid' => '1',
          'doubleopt' => '0',
          'Submit' => 'Submit'
        )
        expect { service_provider.name_param }.to raise_error ServiceProviders::EmbedCodeProvider::FirstAndLastNameRequired
      end
    end

    context 'iContact automatic' do
      let(:provider) { 'icontact' }
      let(:file) { 'icontact_manual' }
      it 'works' do
        expect(service_provider.class).to eq(ServiceProviders::IContact)

        expect(service_provider.list_url).to be_nil
        expect(service_provider.action_url).to eq('https://app.icontact.com/icp/signup.php')
        expect(service_provider.email_param).to eq('fields_email')
        expect(service_provider.name_params).to eq(['fields_fname', 'fields_lname'])
        expect(service_provider.required_params).to eq(
          'redirect' => 'http://www.hellobar.com/emailsignup/icontact/success',
          'errorredirect' => 'http://www.hellobar.com/emailsignup/icontact/error',
          'listid' => '10108',
          'specialid:10108' => 'O2D3',
          'clientid' => '1450422',
          'formid' => '564',
          'reallistid' => '1',
          'doubleopt' => '0',
          'Submit' => 'Submit'
        )
        expect { service_provider.name_param }.to raise_error ServiceProviders::EmbedCodeProvider::FirstAndLastNameRequired
      end
    end

    context 'my emma' do
      let(:provider) { 'my_emma' }

      %w(my_emma my_emma_js my_emma_iframe my_emma_popup).each do |file|
        let(:file) { file }
        it "works with My Emma #{ file }".strip do
          expect(service_provider.list_url).to eq('https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a')
          expect(service_provider.action_url).to eq(service_provider.list_url) # same for my emma
          expect(service_provider.email_param).to eq('email')
          expect(service_provider.required_params.keys).to include 'prev_member_email'
        end
      end
    end
  end

  describe '#embed_code=' do
    it 'should raise error' do
      expect { identity.embed_code = 'asdf' }.to raise_error NoMethodError
    end
  end
end
