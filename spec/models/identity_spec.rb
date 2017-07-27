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

  describe '#destroy' do
    it 'destroys the identity' do
      identity.destroy

      expect(identity).to be_destroyed
    end

    context 'when identity is connected to a contact list' do
      let!(:contact_list) { create :contact_list, identity: identity }

      it 'destroys the identity' do
        identity.destroy

        expect(identity).to be_destroyed
      end

      it 'sets identity_id to null at contact list' do
        identity.destroy

        expect(contact_list.reload.identity_id).to be_nil
      end
    end
  end

  describe '#provider_icon_path' do
    let(:identity) { create(:identity, :drip, site: site) }

    it 'returns icon path' do
      expect(identity.provider_icon_path).to eql 'providers/drip.png'
    end
  end

  describe '#provider_name' do
    let(:identity) { create(:identity, :aweber, site: site) }

    it 'returns icon path' do
      expect(identity.provider_name).to eql 'AWeber'
    end
  end
end
