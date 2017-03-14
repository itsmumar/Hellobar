require 'spec_helper'

describe SiteMembership do

  describe 'validations' do
    let(:site_membership)           { create(:site_membership) }
    let(:duplicate_site)            { create(:site, url: site_membership.site.url) }
    let(:duplicate_site_membership) { build(:site_membership, site: duplicate_site, user: user) }
    let!(:user)                     { site_membership.user }

    it 'is valid' do
      expect(site_membership).to be_valid
    end

    it 'catches duplicate site urls' do
      expect(duplicate_site_membership.valid?).to eq(false)
      expect(duplicate_site_membership.errors.full_messages).to(
        include("User already has a membership to #{ duplicate_site.url }")
      )
    end
  end

  describe 'can_destroy?' do
    it 'returns false if there are no other owners' do # ie, sites need at least one owner
      membership = create(:site_membership)
      membership.can_destroy?.should be_false
    end

    it 'returns true if there are other owners' do # ie, sites need at least one owner
      site = create(:site, :with_user)
      create(:site_ownership, site: site)
      ownership = create(:site_ownership, site: site)
      ownership.can_destroy?.should be_true
    end
  end

  it 'should soft-delete' do
    ownership = create(:site_ownership)
    ownership.destroy
    SiteMembership.only_deleted.should include(ownership)
  end
end
