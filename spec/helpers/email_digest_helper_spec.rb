describe EmailDigestHelper, type: :helper do
  context 'format_number' do
    it 'should format 1,580 as 1.6k' do
      expect(helper.format_number(1_580)).to eq('1.6k')
    end

    it 'should format 12,800 as 13k' do
      expect(helper.format_number(12_800)).to eq('13k')
    end

    it 'should format 874 as 874' do
      expect(helper.format_number(874)).to eq('874')
    end

    it 'should format 112,500 as 112k' do
      expect(helper.format_number(112_300)).to eq('112k')
    end
  end

  context 'formatted_percent' do
    it 'should format 0.53' do
      expect(helper.formatted_percent(0.53)).to eq('+0.53%')
    end

    it 'should format 1.64' do
      expect(helper.formatted_percent(1.64)).to eq('+1.6%')
    end

    it 'should format 11.78' do
      expect(helper.formatted_percent(11.78)).to eq('+12%')
    end

    it 'should format 118.3' do
      expect(helper.formatted_percent(118.3)).to eq('+118%')
    end

    it 'should format -89.3' do
      expect(helper.formatted_percent(-89.3)).to eq('-89%')
    end
  end

  context 'conversion_header' do
    it 'should use the conversion unit if all elements are the same type' do
      elements = [
        SiteElement.new(element_subtype: SiteElement::BAR_TYPES.keys[3]),
        SiteElement.new(element_subtype: SiteElement::BAR_TYPES.keys[3])
      ]
      expect(helper.conversion_header(elements)).to eq(SiteElement::BAR_TYPES[SiteElement::BAR_TYPES.keys[3]])
    end

    it "should use the 'Conversions' if mix of element types" do
      elements = [
        SiteElement.new(element_subtype: SiteElement::BAR_TYPES.keys[3]),
        SiteElement.new(element_subtype: SiteElement::BAR_TYPES.keys[2])
      ]
      expect(helper.conversion_header(elements)).to eq('Conversions')
    end
  end
end
