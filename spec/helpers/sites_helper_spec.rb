require 'spec_helper'

describe SitesHelper do
  fixtures :all

  describe "display_name_for_site" do
    it "returns shorter URLs for different sites" do
      site = Site.new(:url => "http://asdf.com")
      helper.display_name_for_site(site).should == "asdf.com"

      site = Site.new(:url => "http://cs.horse.bike")
      helper.display_name_for_site(site).should == "cs.horse.bike"
    end
  end

  describe "sites_for_team_view" do
    it "should rank by current site followed by alphabetical sorting" do
      user = users(:joey)
      user.sites.destroy_all
      s1 = user.sites.create(url: "http://asdf.com")
      s2 = user.sites.create(url: "http://bsdf.com")
      s3 = user.sites.create(url: "http://zsdf.com")
      helper.stub(:current_user).and_return(user)
      helper.stub(:current_site).and_return(s2)
      helper.sites_for_team_view.should == [s2, s1, s3]
    end
  end
end
