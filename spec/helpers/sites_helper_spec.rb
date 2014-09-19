require 'spec_helper'

describe SitesHelper do
  fixtures :all

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

  describe "create_targeted_content_link" do
    it "uses an existing rule if one already matches" do
      link = create_targeted_content_link(sites(:zombo), "dv:mobile")
      link.should =~ /rule_id=#{rules(:zombo_mobile).id}/
    end

    it "links to editor with segment and value in params if no matching rule exists" do
      link = create_targeted_content_link(sites(:zombo), "co:Russia")
      link.should =~ /\?.*segment=co/
      link.should =~ /\?.*value=Russia/
    end
  end

  describe "rule_for_segment_and_value" do
    it "returns a rule if it has a single condition of 'segment is value'" do
      rule = rule_for_segment_and_value(sites(:zombo), "dv", "mobile")
      rule.should == rules(:zombo_mobile)
    end
  end
end
