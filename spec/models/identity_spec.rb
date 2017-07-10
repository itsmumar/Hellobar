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
    specify { expect { identity.destroy }.to change(identity, :destroyed?) }

    context 'when identity has contact_lists' do
      before { create :contact_list, identity: identity }

      it 'returns nothing' do
        expect(identity.destroy).to be_nil
        expect(identity).not_to be_destroyed
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
