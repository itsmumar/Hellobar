require 'spec_helper'

describe SiteMembership do
  fixtures :all

  describe "can_destroy?" do
    it "returns false if there are no other owners" do #ie, sites need at least one owner
      membership = site_memberships(:horsebike)
      membership.can_destroy?.should be_false
    end

    it "returns true if there are other owners" do #ie, sites need at least one owner
      s = sites(:zombo)
      membership = SiteMembership.create(:site => s, :user => users(:wootie), :role => "owner")
      SiteMembership.create(:site => s, :user => users(:joey), :role => "owner")
      membership.can_destroy?.should be_true
    end
  end

  it "should soft-delete" do
    membership = SiteMembership.create(:site => sites(:zombo), :user => users(:wootie), :role => "owner")
    membership.destroy
    SiteMembership.only_deleted.should include(membership)
  end
end
