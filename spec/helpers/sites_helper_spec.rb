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
end
