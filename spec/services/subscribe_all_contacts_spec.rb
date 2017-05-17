describe SubscribeAllContacts do
  let(:contact_list) { create :contact_list, :mailchimp }
  let(:list_id) { contact_list.data['remote_id'] }
  let(:double_optin) { contact_list.double_optin }
  let(:contacts) { create_list :data_api_contact, 10 }
  let(:subscribers) { contacts.map { |(email, name, time)| { email: email, name: name, created_at: time } } }
  let(:service) { described_class.new(contact_list) }

  before { allow(contact_list).to receive(:syncable?).and_return(true) }
  before { allow(Hello::DataAPI).to receive(:contacts).and_return(contacts) }

  context 'when service provider is a EmbedCodeProvider' do
    let(:contact_list) { create :contact_list, :embed_code_form }

    before { allow(contact_list.service_provider).to receive(:action_url).and_return('action_url') }

    it 'sends post request to service_provider.action_url' do
      subscribers.each do |subscriber|
        params = { 'signup[email]' => subscriber[:email], 'signup[name]' => subscriber[:name] }
        expect(HTTParty).to receive(:post).with('action_url', body: params)
      end
      service.call
    end
  end

  context 'when contact list has oauth' do
    before { allow(contact_list).to receive(:oauth?).and_return(true) }

    it 'calls batch_subscribe on identity' do
      expect(contact_list.service_provider).to receive(:batch_subscribe).with(list_id, subscribers, double_optin)
      service.call
    end
  end

  context 'when contact list has api key' do
    before { allow(contact_list).to receive(:api_key?).and_return(true) }

    it 'calls batch_subscribe on identity' do
      expect(contact_list.service_provider).to receive(:batch_subscribe).with(list_id, subscribers, double_optin)
      service.call
    end
  end

  context 'when contact list has a webhook' do
    before { allow(contact_list).to receive(:webhook?).and_return(true) }

    it 'calls batch_subscribe on identity' do
      expect(contact_list.service_provider).to receive(:batch_subscribe).with(list_id, subscribers, double_optin)
      service.call
    end
  end

  context 'with not syncable contact_list' do
    before { allow(contact_list).to receive(:syncable?).and_return(false) }

    it 'does nothing' do
      expect(service.call).to be_nil
    end
  end

  context 'with empty Hello::DataAPI.contacts' do
    before { allow(Hello::DataAPI).to receive(:contacts).and_return([]) }

    it 'does nothing' do
      expect(contact_list.service_provider).not_to receive(:batch_subscribe)
      expect(service.call).to be_empty
    end
  end

  describe 'email syncing errors' do
    let(:identity) { contact_list.identity }

    before do
      allow(Hello::DataAPI).to receive(:contacts).and_return(%i[foo bar])
      allow(contact_list).to receive(:syncable?).and_return(true)
      allow(contact_list).to receive(:oauth?).and_return(true)
    end

    describe 'for mailchimp' do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::MailChimp)
      end

      specify 'if someone has an invalid list stored, delete the identity and notify them' do
        expect(contact_list.service_provider).to receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new('MailChimp API Error: Invalid MailChimp List ID'))
        expect(contact_list.identity).to receive :destroy_and_notify_user
        service.call
      end

      specify "if someone's token is no longer valid, delete the identity and notify them" do
        expect(contact_list.service_provider).to receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new('MailChimp API Error: Invalid Mailchimp API Key'))
        expect(contact_list.identity).to receive :destroy_and_notify_user
        service.call
      end

      specify 'if someone has deleted their account, delete the identity and notify them' do
        expect(contact_list.service_provider).to receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new('MailChimp API Error: This account has been deactivated'))
        expect(contact_list.identity).to receive :destroy_and_notify_user
        service.call
      end
    end

    describe 'for campaign monitor' do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::CampaignMonitor)
      end

      specify 'if someone has revoked our access, delete the identity and notify them' do
        expect(contact_list.service_provider).to receive(:batch_subscribe).and_raise(CreateSend::RevokedOAuthToken.new(Hashie::Mash.new(Code: 122, Message: 'Revoked OAuth Token')))
        expect(contact_list.identity).to receive :destroy_and_notify_user
        service.call
      end
    end

    describe 'for aweber' do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::AWeber)
      end

      specify 'if someone has an invalid list stored, delete the identity and notify them' do
        expect(contact_list.service_provider).to receive(:batch_subscribe).and_raise(URI::InvalidURIError.new('404 Resource Not Found'))
        expect(contact_list.identity).to receive :destroy_and_notify_user
        service.call
      end

      specify "if someone's token is no longer valid, or they have deleted their account, delete the identity and notify them" do
        expect(contact_list.service_provider).to receive(:batch_subscribe).and_raise(ArgumentError.new('This account has been deactivated'))
        expect(contact_list.identity).to receive :destroy_and_notify_user
        service.call
      end
    end

    describe 'for constantcontact' do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::ConstantContact)
      end

      def rest_response(status, body)
        RestClient::Response.create body, OpenStruct.new(code: status, body: body), nil, nil
      end

      specify 'if someone has an invalid list stored, delete the identity and notify them' do
        response = rest_response(404, '404 Resource Not Found')
        expect(contact_list.service_provider).to receive(:batch_subscribe).and_raise(RestClient::ResourceNotFound.new(response))
        expect(contact_list.identity).to receive :destroy_and_notify_user
        service.call
      end
    end
  end
end
