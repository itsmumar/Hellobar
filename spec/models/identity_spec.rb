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
  end

  describe '#active?' do
    context 'when persisted and filled out' do
      it 'returns true' do
        expect(identity).to be_active
      end
    end
  end

  describe '#destroy_and_notify_user' do
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

  describe '#embed_code=' do
    it 'should raise error' do
      expect { identity.embed_code = 'asdf' }.to raise_error NoMethodError
    end
  end
end
