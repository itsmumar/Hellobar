describe SiteElementSerializer do
  let(:element) { create(:site_element, :traffic) }
  let(:serializer) { SiteElementSerializer.new(element) }

  it 'serializes :email_redirect' do
    site_element = build_stubbed :site_element, :email_with_redirect

    serialized_site_element = SiteElementSerializer.new site_element

    expect(serialized_site_element.serializable_hash).to have_key :email_redirect
  end

  context 'with scope' do
    let(:user) { create(:user) }
    let(:serializer) { SiteElementSerializer.new(element, scope: user) }

    it 'passes the scope to the site serializer' do
      expect(SiteSerializer).to receive(:new).with(element.site, scope: user)
      serializer.as_json
    end
  end

  describe '#preset_rule_name' do
    context 'with an editable rule' do
      let(:rule) { create :rule, editable: true }
      let(:element) { create(:site_element, :traffic, rule: rule) }

      specify { expect(serializer.preset_rule_name).to eql 'Saved' }
    end

    context 'with an non-editable rule' do
      let(:rule) { create :rule, editable: false }
      let(:element) { create(:site_element, :traffic, rule: rule) }

      specify { expect(serializer.preset_rule_name).to eql rule.name }
    end
  end
end
