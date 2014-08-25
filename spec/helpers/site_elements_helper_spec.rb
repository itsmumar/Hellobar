require 'spec_helper'

describe SiteElementsHelper do
  describe "site_element_subtypes_for_site" do
    fixtures :all
    
    let(:site) { Site.new(:url => "http://asdf.com") }
    let(:rule) { Rule.new }
    before do
      site.rules << rule
      rule.site_elements = elements
      site.save!
    end

    context "none" do
      let(:elements) { [] }

      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to eq([])
      end
    end

    context "traffic" do
      let(:elements) { [ site_elements(:zombo_traffic) ] }

      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to eq(["traffic"])
      end
    end

    context "email" do
      let(:elements) { [ site_elements(:zombo_email) ] }
      
      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to eq(["email"])
      end
    end

    context "multiple" do
      let(:elements) { [ site_elements(:zombo_traffic), site_elements(:zombo_email) ] }
      
      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to match_array(["traffic", "email"])
      end
    end
  end
end
