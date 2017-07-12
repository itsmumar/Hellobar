describe DestroyIdentity do
  let!(:identity) { create :identity }
  let(:service) { DestroyIdentity.new(identity) }

  describe '#call' do
    it 'destroys identity' do
      expect { service.call }.to change(Identity, :count).by(-1)
    end

    context 'even when contact lists connected to identity' do
      let!(:conntact_list) { create :contact_list, identity: identity }

      it 'destroys identity' do
        expect { service.call }
          .to change(Identity, :count).by(-1)
          .and change { conntact_list.reload.identity }.to nil
      end
    end

    context 'with notify_user: true' do
      let(:site) { create :site, :with_user }
      let!(:identity) { create :identity, :mailchimp, site: site }
      let(:service) { DestroyIdentity.new(identity, notify_user: true) }

      it 'emails the user that there was a problem syncing their identity' do
        expect(MailerGateway).to receive(:send_email) do |type, recipient, params|
          expect(type).to eql 'Integration Sync Error'
          expect(recipient).to eql site.owners.first.email
          expect(params[:link]).to match(/http\S+sites\S+#{site.id}/)
          expect(params[:integration_name]).to eql 'MailChimp'
        end

        service.call
      end
    end
  end
end
