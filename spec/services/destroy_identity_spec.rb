describe DestroyIdentity do
  let!(:identity) { create :identity }
  let(:service) { DestroyIdentity.new(identity) }

  around { |example| perform_enqueued_jobs(&example) }

  describe '#call' do
    it 'destroys identity' do
      expect { service.call }.to change(Identity, :count).by(-1)
    end

    context 'even when contact lists connected to identity' do
      let!(:conntact_list) { create :contact_list, identity: identity }

      it 'destroys identity' do
        expect { service.call }
          .to change(Identity, :count)
          .by(-1)
          .and change { conntact_list.reload.identity }
          .to nil
      end
    end

    context 'with notify_user: true' do
      let(:site) { create :site, :with_user }
      let!(:identity) { create :identity, :mailchimp, site: site }
      let(:service) { DestroyIdentity.new(identity, notify_user: true) }

      it 'emails the user that there was a problem syncing their identity' do
        expect(IntegrationMailer)
          .to receive(:sync_error)
          .with(site.owners.first, site, identity.provider_name)
          .and_call_original.twice

        service.call

        expect(last_email_sent)
          .to have_subject "There was a problem syncing your #{ identity.provider_name } account"
      end
    end
  end
end
