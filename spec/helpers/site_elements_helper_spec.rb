require 'spec_helper'

describe SiteElementsHelper do
  describe "site_element_subtypes_for_site" do
    fixtures :all
    let(:site) { sites(:zombo) }

    context "none" do
      before do
        site.stub(:site_elements => [])
      end

      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to eq([])
      end
    end

    context "traffic" do
      before do
        site.stub(:site_elements => [site_elements(:zombo_traffic)])
      end

      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to eq(["traffic"])
      end
    end

    context "email" do
      before do
        site.stub(:site_elements => [site_elements(:zombo_email)])
      end

      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to eq(["email"])
      end
    end

    context "multiple" do
      before do
        site.stub(:site_elements => [site_elements(:zombo_traffic), site_elements(:zombo_email)])
      end

      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to match_array(["traffic", "email"])
      end
    end
  end
end
