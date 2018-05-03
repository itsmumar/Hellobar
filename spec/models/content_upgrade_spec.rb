describe ContentUpgrade do
  let(:model) { build :content_upgrade, id: 1 }

  specify { expect(model).to have_attached_file :content_upgrade_pdf }
  specify { expect(model).to validate_attachment_presence(:content_upgrade_pdf) }
  specify { expect(model).to validate_attachment_content_type(:content_upgrade_pdf).allowing('application/pdf') }

  describe '.content_upgrade_download_link', :freeze do
    it 'returns url to attached file' do
      expect(model.content_upgrade_download_link)
        .to match "/test_content_upgrades/000/000/001/original.pdf?#{ Time.current.to_i }"
    end
  end

  describe '.content_upgrade_script_tag' do
    let(:content) { %(window.onload = function() {hellobar("contentUpgrades").show(#{ model.id });};) }
    let(:tag) { %(<script id="hb-cu-#{ model.id }">#{ content }</script>) }

    it 'returns <script> which should be used in target page' do
      expect(model.content_upgrade_script_tag).to eql tag
    end
  end

  describe '#display_title' do
    subject { model.display_title }

    context 'when there is a title set' do
      let(:model) { build(:content_upgrade, offer_headline: 'offer_headline', content_upgrade_title: 'title') }

      it { expect(subject).to eq 'title' }
    end

    context 'when there is no title set' do
      let(:model) { build(:content_upgrade, offer_headline: 'offer_headline') }

      it { expect(subject).to eq 'offer_headline' }
    end
  end
end
