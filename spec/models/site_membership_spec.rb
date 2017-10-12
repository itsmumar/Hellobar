describe SiteMembership do
  it 'will not allow creating a 2nd membership for the same user and site' do
    site_membership = create :site_membership

    duplicate_site_membership = build :site_membership,
      site: site_membership.site, user: site_membership.user

    expect(duplicate_site_membership).to be_invalid
    expect(duplicate_site_membership.errors.full_messages.first)
      .to include 'already has a membership'
  end

  it 'it soft-deletes when object is being destroyed' do
    ownership = create :site_membership
    ownership.destroy

    expect(SiteMembership.only_deleted).to include ownership
  end

  describe '#can_destroy?' do
    it 'returns false if there are no other owners' do # ie, sites need at least one owner
      membership = create(:site_membership)

      expect(membership.can_destroy?).to be_falsey
    end

    it 'returns true if there are other owners' do # ie, sites need at least one owner
      site = create(:site, :with_user)
      create(:site_membership, site: site)

      ownership = create(:site_membership, site: site)

      expect(ownership.can_destroy?).to be_truthy
    end
  end
end
