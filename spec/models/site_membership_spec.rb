require 'spec_helper'

describe SiteMembership do
  fixtures :all

  describe "validations" do
    let!(:user) { create(:user) }

    it "#user_site_url_uniqueness" do
      site1 = Site.create(:url => "zombo.com")
      site2 = Site.create(:url => "zombo.com")
      site_membership1 = user.site_memberships.create(site: site1, role: "owner")
      site_membership2 = user.site_memberships.create(site: site2, role: "owner")
      expect(site_membership2.errors.messages[:user]).to include("already has a membership to http://zombo.com")
    end
  end

  describe "can_destroy?" do
    it "returns false if there are no other owners" do #ie, sites need at least one owner
      membership = site_memberships(:horsebike)
      membership.can_destroy?.should be_false
    end

    it "returns true if there are other owners" do #ie, sites need at least one owner
      ownership = create(:site_ownership, site: sites(:zombo), user: users(:wootie))
      ownership.can_destroy?.should be_true
    end
  end

  it "should soft-delete" do
    ownership = create(:site_ownership, site: sites(:zombo), user: users(:wootie))
    ownership.destroy
    SiteMembership.only_deleted.should include(ownership)
  end
end
