require 'spec_helper'

describe SitesHelper do
  describe "display_url_for_site" do
    it "returns shorter URLs for different sites" do
      site = Site.new(:url => "http://asdf.com")
      helper.display_url_for_site(site).should == "asdf.com"

      site = Site.new(:url => "http://cs.horse.bike")
      helper.display_url_for_site(site).should == "cs.horse.bike"
    end
  end

  describe "segment_description" do
    it "correctly expands short segment strings into humanized descriptions" do
      segment_description("co:USA").should == "Country is USA"
      segment_description("dv:Mobile").should == "Device is Mobile"
    end

    it "correctly expands short segment strings when value contains a colin" do
      segment_description("rf:http://zombo.com").should == "Referrer URL is http://zombo.com"
    end
  end
end
