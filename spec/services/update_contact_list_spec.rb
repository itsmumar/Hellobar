describe UpdateContactList do
  let(:identity) { create :identity, :drip }
  let(:embed_code) { create :embed_code, provider: 'my_emma' }
  let(:contact_list) { create :contact_list, identity: identity, data: { embed_code: embed_code } }
  let(:params) { { provider_token: 'drip', name: 'Changed' } }
  let(:service) { UpdateContactList.new(contact_list, params) }

  describe '#call' do
    it 'updates attributes' do
      expect { service.call }.to change(contact_list, :name).to('Changed')
    end

    context 'when provider_token is an embed code token' do
      before { allow(ServiceProvider).to receive(:embed_code?).and_return true }
      before { allow_any_instance_of(ContactList).to receive(:embed_code_valid?).and_return true }

      let(:params) do
        { provider_token: 'my_emma', name: 'Changed', data: { embed_code: create(:embed_code, provider: 'my_emma') } }
      end

      it 'creates identity' do
        expect { service.call }.to change(Identity.where(provider: 'my_emma'), :count).to(1)
      end
    end

    context 'when provider_token is webhooks' do
      let(:params) do
        { provider_token: 'webhooks', name: 'Changed', data: { webhook_url: 'http://localhost' } }
      end

      it 'creates identity' do
        expect { service.call }.to change(Identity.where(provider: 'webhooks'), :count).to(1)
      end
    end

    context 'when provider_token is 0, i.e. hellobar' do
      let(:params) do
        { provider_token: '0', name: 'Changed' }
      end

      it 'does not create identity' do
        expect { service.call }.not_to change(Identity, :count)
      end
    end

    context 'when identity_id is changed' do
      let!(:new_identity) { create :identity, :aweber }
      let!(:params) { { provider_token: 'aweber', identity: new_identity, name: 'Changed' } }

      it 'changes identity' do
        expect { service.call }.to change(contact_list, :identity_id).to(new_identity.id)
      end

      context 'and identity does not have contact lists' do
        it 'destroys identity' do
          expect { service.call }
            .to change(contact_list, :name)
            .to('Changed')
            .and change(Identity, :count)
            .by(-1)
        end
      end

      context 'and identity has more contact lists' do
        before { create :contact_list, identity: identity }

        let(:params) { { provider_token: 'aweber', name: 'Changed' } }

        it 'does not destroy identity' do
          expect { service.call }.not_to change(Identity, :count)
        end
      end
    end
  end
end
