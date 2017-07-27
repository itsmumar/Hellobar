describe SiteStatistics, freeze: '2017-01-03' do
  let(:site_element_statistics) { create_list :site_element_statistics, 5, views: [1, 2, 3], conversions: [1, 2, 3] }
  let(:model) { SiteStatistics.new([1, 2, 3, 4, 5].zip(site_element_statistics).to_h) }

  describe '#views' do
    it 'sums all views' do
      expect(model.views).to eql site_element_statistics.sum(&:views).to_f
    end
  end

  describe '#views?' do
    subject { model.views? }

    context 'when views > 0' do
      before { allow(model).to receive(:views).and_return 1 }
      specify { is_expected.to be_truthy }
    end

    context 'when views < 1' do
      before { allow(model).to receive(:views).and_return 0 }
      specify { is_expected.to be_falsey }
    end
  end

  describe '#conversions' do
    it 'sums all conversions' do
      expect(model.conversions).to eql site_element_statistics.sum(&:conversions).to_f
    end
  end

  describe '#totals' do
    it 'sums all site element statistics' do
      expect(model.totals).to be_a SiteElementStatistics
      expect(model.totals.views).to eql site_element_statistics.sum(&:views).to_f
      expect(model.totals.conversions).to eql site_element_statistics.sum(&:conversions).to_f
    end
  end

  describe '#for_goal' do
    let(:site_elements) { create_list :site_element, 3, :click_to_call }

    let(:site_element_statistics) do
      site_elements.each_with_object({}) do |element, hash|
        hash[element.id] = create(:site_element_statistics, :with_views)
      end
    end

    let(:model) { SiteStatistics.new(site_element_statistics) }

    it 'sums all site element statistics' do
      expect(model.for_goal(:click)).to be_a SiteElementStatistics
      expect(model.for_goal(:click).views).to eql site_element_statistics.values.sum(&:views).to_f
      expect(model.for_goal(:click).conversions).to eql site_element_statistics.values.sum(&:conversions).to_f
    end
  end
end
