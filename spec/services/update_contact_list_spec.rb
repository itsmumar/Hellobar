describe UpdateContactList do
  let(:identity) { create :identity, :drip }
  let(:contact_list) { create :contact_list, identity: identity }
  let(:params) { { provider_token: 'drip', name: 'Changed' } }
  let(:service) { UpdateContactList.new(contact_list, params) }

  describe '#call' do
    it 'updates attributes' do
      expect { service.call }.to change(contact_list, :name).to('Changed')
    end

    context 'when identity_id is changed' do
      let!(:new_identity) { create :identity, :aweber }
      let!(:params) { { identity: new_identity, name: 'Changed' } }

      it 'changes identity' do
        expect { service.call }.to change(contact_list, :identity_id).to(new_identity.id)
      end

      context 'and identity does not have contact lists' do
        it 'destroys identity' do
          expect { service.call }
            .to change(contact_list, :name).to('Changed')
            .and change(Identity, :count).by(-1)
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
