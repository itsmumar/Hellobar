describe TargetedSegmentsHelper do
  let(:site) { create(:site, :with_rule) }

  before do
    create(:condition, :mobile, rule: site.rules.first)
  end

  describe 'segment_description' do
    it 'correctly expands short segment strings into humanized descriptions' do
      expect(segment_description('co:USA')).to eq('Country is USA')
      expect(segment_description('dv:Mobile')).to eq('Device is Mobile')
    end

    it 'correctly expands short segment strings when value contains a colin' do
      expect(segment_description('rf:http://zombo.com')).to eq('Referrer URL is http://zombo.com')
    end
  end

  describe 'create_targeted_content_link' do
    it 'uses an existing rule if one already matches' do
      link = create_targeted_content_link(site, 'dv:mobile')
      expect(link).to match(/rule_id=#{site.rules.first.id}/)
    end

    it 'links to targeted segments controller if no matching rule exists' do
      link = create_targeted_content_link(site, 'dv:desktop')
      expect(link).to match(/targeted_segments/)
      expect(link).to match(/dv%3Adesktop/)
    end
  end

  describe 'rule_for_segment_and_value' do
    it "returns a rule if it has a single condition of 'segment is value'" do
      rule = rule_for_segment_and_value(site, 'dv', 'mobile')
      expect(rule).to eq(site.rules.first)
    end
  end
end
