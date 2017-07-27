describe UpdateContactList do
  let(:contact_list) { create :contact_list }
  let(:name) { 'New name' }
  let(:provider) { 'my_emma' }
  let(:service) { UpdateContactList.new(contact_list, params) }

  describe '#call' do
    context 'when there is no identity attached and we are changing the name' do
      let(:params) { Hash[name: name] }

      it 'updates contact list' do
        expect { service.call }.to change(contact_list, :name).to name
      end
    end

    context 'when attaching embed code provider' do
      let(:contact_list) { create :contact_list }
      let(:embed_code) { create(:embed_code, provider: provider) }
      let(:params) do
        {
          provider_token: 'my_emma',
          data: {
            embed_code: embed_code
          }
        }
      end

      before do
        allow_any_instance_of(ContactList).to receive(:embed_code_valid?).and_return true
      end

      it 'creates a new identity' do
        expect { service.call }
          .to change(Identity.where(provider: provider), :count).to(1)
      end

      it 'associates new identity to the contact list' do
        service.call
        expect(contact_list.reload.identity.provider).to eql provider
      end
    end

    context 'when attaching webhooks' do
      let(:provider) { 'webhooks' }
      let(:params) do
        {
          provider_token: provider,
          data: {
            webhook_url: 'http://localhost'
          }
        }
      end

      it 'creates a new identity' do
        expect { service.call }
          .to change(Identity.where(provider: provider), :count)
          .by(1)
      end

      it 'associates new identity to the contact list' do
        service.call
        expect(contact_list.reload.identity.provider).to eql provider
      end
    end

    context 'when provider_token is 0 (hellobar)' do
      let(:params) { Hash[provider_token: '0'] }

      it 'does not create a new identity' do
        expect { service.call }.not_to change(Identity, :count)
      end
    end

    context 'when provider is changed' do
      let(:contact_list) { create :contact_list, :drip }
      let(:new_identity) { create :identity, :aweber, site: contact_list.site }
      let(:params) { Hash[identity: new_identity] }

      it 'destroys existing identity' do
        identity = contact_list.identity

        service.call

        expect(identity).to be_destroyed
      end

      it 'creates a new identity' do
        expect { service.call }
          .to change(Identity.where(provider: 'aweber'), :count)
          .by(1)
      end
    end
  end
end
