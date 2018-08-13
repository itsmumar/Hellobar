describe SiteElementEditorHelper do
  describe 'skip_interstitial?' do
    before do
      allow(helper).to receive(:params).and_return(params)
    end
    let(:params) { {} }

    it 'should render the interstitial' do
      expect(helper.skip_interstitial?).to be_falsey
    end

    context 'copying an existing site element' do
      let(:params) { { element_to_copy_id: 1 } }

      it 'should not render the interstitial' do
        expect(helper.skip_interstitial?).to be_truthy
      end
    end

    context 'skipping the onboarding interstitial' do
      let(:params) { { skip_interstitial: true } }

      it 'should not render the interstitial' do
        expect(helper.skip_interstitial?).to be_truthy
      end
    end
  end
end
