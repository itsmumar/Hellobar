describe SiteStatistics, freeze: '2017-01-03' do
  let(:first_record) { create(:site_statistics_record, site_element_id: 1) }
  let(:second_record) { create(:site_statistics_record, site_element_id: 2) }
  let(:third_record) { create(:site_statistics_record, site_element_id: 3) }

  let(:records) { [first_record, second_record, third_record] }
  let(:model) { SiteStatistics.new(records) }

  describe '#for_element' do
    it 'returns SiteStatistics with records which have a given site element id' do
      expect(model.for_element(2)).to be_a SiteStatistics
      expect(model.for_element(2).views).to eql second_record.views
    end
  end

  describe '#site_element_ids' do
    it 'returns all site element ids' do
      expect(model.site_element_ids).to eql records.map(&:site_element_id)
    end
  end

  describe '#days' do
    it 'returns uniq record dates' do
      expect(model.days).to eql [Date.current]
    end
  end

  describe '#with_views' do
    let(:third_record) { create(:site_statistics_record, views: 0, site_element_id: 3) }

    it 'returns a scope with records that have views > 0' do
      expect(model.with_views)
        .to match_array([first_record, second_record])
        .and be_a SiteStatistics
    end
  end

  describe '#between' do
    let(:third_record) { create(:site_statistics_record, date: 2.days.ago) }

    it 'returns a scope with records that have views > 0' do
      expect(model.between(1.day.ago)).to match_array [first_record, second_record]
      expect(model.between(1.day.ago, Date.current))
        .to match_array([first_record, second_record])
        .and be_a SiteStatistics
    end
  end

  describe '#until' do
    let(:third_record) { create(:site_statistics_record, date: 2.days.ago) }

    it 'returns a scope with records that have views > 0' do
      expect(model.until(1.day.ago))
        .to match_array([third_record])
        .and be_a SiteStatistics
    end
  end

  describe '#for_goal' do
    let(:first_record) do
      create(:site_statistics_record, site_element_id: 1, goal: :foo)
    end

    it 'returns SiteStatistics with records which have a given goal' do
      expect(model.for_goal(:foo)).to be_a SiteStatistics
      expect(model.for_goal(:foo).views).to eql first_record.views
      expect(model.for_goal(:foo).conversions).to eql first_record.conversions
    end
  end

  describe '#views' do
    it 'sums all views' do
      expect(model.views).to eql records.sum(&:views)
    end
  end

  describe '#conversions' do
    it 'sums all conversions' do
      expect(model.conversions).to eql records.sum(&:conversions)
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

  describe '#<<' do
    let(:last_record) { model.records.last }
    before { model.clear }

    it 'creates SiteStatistics::Record and appends it to array' do
      model << { 'v' => 100, 'c' => 10, 'date' => 2.days.ago, 'sid' => 1, 'goal' => 'call' }
      expect(last_record).to be_a SiteStatistics::Record
      expect(last_record.conversions).to eql 10
      expect(last_record.views).to eql 100
      expect(last_record.date).to eql 2.days.ago
      expect(last_record.site_element_id).to eql 1
      expect(last_record.goal).to eql :call
    end
  end

  describe '#conversion_rate' do
    it 'returns proportion of conversion/views' do
      expect(model.conversion_rate).to eql(model.conversions.to_f / model.views)
    end
  end

  describe '#conversion_percent' do
    it 'returns proportion of conversion/views' do
      expect(model.conversion_percent).to eql(model.conversion_rate * 100)
    end
  end
end
