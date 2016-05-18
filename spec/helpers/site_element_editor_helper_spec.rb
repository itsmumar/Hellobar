require 'spec_helper'

describe SiteElementEditorHelper do
  fixtures :all

  describe "render_interstitial?" do
    before do
      helper.stub(:params).and_return(params)
      helper.stub(:get_ab_variation).with("Forced Email Path 2016-03-28").and_return(ab_group)
    end
    let(:params) {{}}
    let(:ab_group) {"original"}

    it "should render the interstitial" do
      expect(helper.render_interstitial?).to eq true
    end

    context "copying an existing site element" do
      let(:params) {{element_to_copy_id: 1}}

      it "should not render the interstitial" do
        expect(helper.render_interstitial?).to eq false
      end
    end

    context "skipping the onboarding interstitial" do
      let(:params) {{skip_interstitial: true}}

      it "should not render the interstitial" do
        expect(helper.render_interstitial?).to eq false
      end
    end

    context "Forced email site elements" do
      let(:ab_group) {"force"}

      it "should not render the interstitial" do
        expect(helper.render_interstitial?).to eq false
      end
    end
  end
end
