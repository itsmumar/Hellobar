describe ContentUpgrade do
  let(:model) { build :content_upgrade, id: 1 }

  describe '.content_upgrade_script_tag' do
    let(:content) { %(window.onload = function() {hellobar("contentUpgrades").show(#{ model.id });};) }
    let(:tag) { %(<script id="hb-cu-#{ model.id }">#{ content }</script>) }

    it 'returns <script> which should be used in target page' do
      expect(model.content_upgrade_script_tag).to eql tag
    end
  end
end
