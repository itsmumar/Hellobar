describe SubscribeContact do
  let(:contact_list) { create :contact_list, :mailchimp }
  let(:list_id) { contact_list.data['remote_id'] }
  let(:double_optin) { contact_list.double_optin }
  let(:email) { 'email@contact.com' }
  let(:name) { 'FirstName LastName' }
  let(:params) { { 'signup[email]' => email, 'signup[name]' => name } }
  let(:contact) { SyncOneContactListWorker::Contact.new(contact_list.id, email, name) }
  let(:service) { described_class.new(contact) }

  before { allow(contact).to receive(:contact_list).and_return(contact_list) }
  before { allow(contact_list).to receive(:syncable?).and_return(true) }

  context 'base behaviour' do
    let(:log_entry) { contact_list.contact_list_logs.last }

    before { allow(contact_list.service_provider).to receive(:subscribe) }

    it 'creates contact list logs' do
      expect { service.call }.to change(contact_list.contact_list_logs, :count).to(1)
    end

    context 'when sucessfully sync' do
      it 'marks contact list log as completed' do
        service.call
        expect(log_entry).to be_completed
      end
    end

    describe 'when error is raised' do
      let(:identity) { contact_list.identity }

      before do
        allow(Hello::DataAPI).to receive(:contacts).and_return(%i[foo bar])
        allow(contact_list).to receive(:syncable?).and_return(true)
        allow(contact_list).to receive(:oauth?).and_return(true)
      end

      after { service.call }

      describe 'for mailchimp' do
        before do
          allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::MailChimp)
        end

        it 'if someone has an invalid list stored, delete the identity and notify them' do
          expect(contact_list.service_provider).to receive(:subscribe).and_raise(Gibbon::MailChimpError.new('MailChimp API Error: Invalid MailChimp List ID'))
          expect(contact_list.identity).to receive :destroy_and_notify_user
        end

        it "if someone's token is no longer valid, delete the identity and notify them" do
          expect(contact_list.service_provider).to receive(:subscribe).and_raise(Gibbon::MailChimpError.new('MailChimp API Error: Invalid Mailchimp API Key'))
          expect(contact_list.identity).to receive :destroy_and_notify_user
        end

        it 'if someone has deleted their account, delete the identity and notify them' do
          expect(contact_list.service_provider).to receive(:subscribe).and_raise(Gibbon::MailChimpError.new('MailChimp API Error: This account has been deactivated'))
          expect(contact_list.identity).to receive :destroy_and_notify_user
        end
      end

      describe 'for campaign monitor' do
        before do
          allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::CampaignMonitor)
        end

        it 'if someone has revoked our access, delete the identity and notify them' do
          expect(contact_list.service_provider).to receive(:subscribe).and_raise(CreateSend::RevokedOAuthToken.new(Hashie::Mash.new(Code: 122, Message: 'Revoked OAuth Token')))
          expect(contact_list.identity).to receive :destroy_and_notify_user
        end
      end

      describe 'for aweber' do
        before do
          allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::AWeber)
        end

        it 'if someone has an invalid list stored, delete the identity and notify them' do
          expect(contact_list.service_provider).to receive(:subscribe).and_raise(URI::InvalidURIError.new('404 Resource Not Found'))
          expect(contact_list.identity).to receive :destroy_and_notify_user
        end

        it "if someone's token is no longer valid, or they have deleted their account, delete the identity and notify them" do
          expect(contact_list.service_provider).to receive(:subscribe).and_raise(ArgumentError.new('This account has been deactivated'))
          expect(contact_list.identity).to receive :destroy_and_notify_user
        end
      end

      describe 'for constantcontact' do
        before do
          allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::ConstantContact)
        end

        def rest_response(status, body)
          RestClient::Response.create body, OpenStruct.new(code: status, body: body), nil, nil
        end

        it 'if someone has an invalid list stored, delete the identity and notify them' do
          response = rest_response(404, '404 Resource Not Found')
          expect(contact_list.service_provider).to receive(:subscribe).and_raise(RestClient::ResourceNotFound.new(response))
          expect(contact_list.identity).to receive :destroy_and_notify_user
        end
      end
    end

    context 'when StandardError is raised' do
      before { allow(contact_list.service_provider).to receive(:subscribe).and_raise StandardError }

      it 'raises error' do
        expect { service.call }.to raise_error StandardError
      end

      it 'does not mark contact list log as completed' do
        expect { service.call }.to raise_error StandardError
        expect(log_entry).not_to be_completed
      end
    end
  end

  context 'when service provider is a EmbedCodeProvider' do
    let(:contact_list) { create :contact_list, :embed_code_form }

    before { allow(contact_list.service_provider).to receive(:action_url).and_return('action_url') }

    it 'sends post request to service_provider.action_url' do
      expect(HTTParty).to receive(:post).with('action_url', body: params)
      service.call
    end
  end

  context 'when contact list has oauth' do
    before { allow(contact_list).to receive(:oauth?).and_return(true) }

    it 'calls subscribe on identity' do
      expect(contact_list.service_provider).to receive(:subscribe).with(list_id, email, name, double_optin)
      service.call
    end
  end

  context 'when contact list has api key' do
    before { allow(contact_list).to receive(:api_key?).and_return(true) }

    it 'calls subscribe on identity' do
      expect(contact_list.service_provider).to receive(:subscribe).with(list_id, email, name, double_optin)
      service.call
    end
  end

  context 'when contact list has a webhook' do
    before { allow(contact_list).to receive(:webhook?).and_return(true) }

    it 'calls subscribe on identity' do
      expect(contact_list.service_provider).to receive(:subscribe).with(list_id, email, name, double_optin)
      service.call
    end
  end

  context 'with not syncable contact_list' do
    before { allow(contact_list).to receive(:syncable?).and_return(false) }

    it 'does nothing' do
      expect(contact_list.service_provider).to be_nil
      expect(service.call).to be_nil
    end
  end
end
