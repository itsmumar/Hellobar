describe ContentUpgrade do
  let(:model) { build :content_upgrade }

  specify { expect(model).to have_attached_file :content_upgrade_pdf }
  specify { expect(model).to validate_attachment_presence(:content_upgrade_pdf) }
  specify { expect(model).to validate_attachment_content_type(:content_upgrade_pdf).allowing('application/pdf') }

  describe '.content_upgrade_download_link' do
    it 'returns url to attached file' do
      expect(model.content_upgrade_download_link)
        .to match '/system/content_upgrades/content_upgrade_pdfs//original/content_upgrade.pdf'
    end
  end

  describe '.content_upgrade_script_tag' do
    let(:content) { %(window.onload = function() {hellobar("contentUpgrades").show(#{ model.id });};) }
    let(:tag) { %(<script id="hb-cu-#{ model.id }">#{ content }</script>) }

    it 'returns <script> which should be used in target page' do
      expect(model.content_upgrade_script_tag).to eql tag
    end
  end
end
