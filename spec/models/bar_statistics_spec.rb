describe BarStatistics, freeze: '2017-01-03' do
  let(:model) { BarStatistics.new(records) }

  let(:two_days_ago) { BarStatistics::Record.new(50, 4, 2.days.ago, 1) }
  let(:one_days_ago) { BarStatistics::Record.new(75, 6, 1.day.ago, 1) }
  let(:today) { BarStatistics::Record.new(100, 10, Date.current, 1) }

  let(:records) { [two_days_ago, one_days_ago, today] }

  describe '#<<' do
    let(:last_record) { model[0] }
    before { model.clear }

    it 'creates BarStatistics::Record and appends it to array' do
      model << { 'v' => 100, 'c' => 10, 'date' => 2.days.ago, 'sid' => 1 }
      expect(last_record).to be_a BarStatistics::Record
      expect(last_record.conversions).to eql 10
      expect(last_record.views).to eql 100
      expect(last_record.date).to eql 2.days.ago
      expect(last_record.site_element_id).to eql 1
    end
  end

  describe '#views' do
    it 'sums all views' do
      expect(model.views).to eql records.sum(&:views).to_f
      expect(model.views(1.day.ago)).to eql [one_days_ago, two_days_ago].sum(&:views).to_f
      expect(model.views(2.days.ago)).to eql two_days_ago.views.to_f
    end
  end

  describe '#has_views?' do
    subject { model }

    context 'when views > 0' do
      before { allow(model).to receive(:views).and_return 1 }
      specify { is_expected.to have_views }
    end

    context 'when views < 1' do
      before { allow(model).to receive(:views).and_return 0 }
      specify { is_expected.not_to have_views }
    end
  end

  describe '#conversions' do
    it 'sums all conversions' do
      expect(model.conversions).to eql records.sum(&:conversions).to_f
      expect(model.conversions(1.day.ago)).to eql [one_days_ago, two_days_ago].sum(&:conversions).to_f
      expect(model.conversions(2.days.ago)).to eql two_days_ago.conversions.to_f
    end
  end

  describe '#views_between' do
    it 'sums views' do
      expect(model.views_between(2.days.ago, 1.day.ago)).to eql [one_days_ago, two_days_ago].sum(&:views).to_f
      expect(model.views_between(1.day.ago)).to eql [one_days_ago, today].sum(&:views).to_f
      expect(model.views_between(Date.current)).to eql today.views.to_f
    end
  end

  describe '#conversions_between' do
    it 'sums conversions' do
      expect(model.conversions_between(2.days.ago, 1.day.ago)).to eql [one_days_ago, two_days_ago].sum(&:conversions).to_f
      expect(model.conversions_between(1.day.ago)).to eql [one_days_ago, today].sum(&:conversions).to_f
      expect(model.conversions_between(Date.current)).to eql today.conversions.to_f
    end
  end

  describe '#conversion_rate' do
    it 'returns proportion of conversion/views' do
      expect(model.conversion_rate(2.days.ago)).to eql(model.conversions(2.days.ago) / model.views(2.days.ago))
      expect(model.conversion_rate(1.day.ago)).to eql(model.conversions(1.days.ago) / model.views(1.days.ago))
      expect(model.conversion_rate(Date.current)).to eql(model.conversions / model.views)
    end
  end

  describe '#conversion_rate_between' do
    it 'returns proportion of conversion/views' do
      expect(model.conversion_rate_between(2.days.ago, 1.day.ago))
        .to eql(model.conversions_between(2.days.ago, 1.day.ago) / model.views_between(2.days.ago, 1.day.ago))

      expect(model.conversion_rate_between(1.day.ago))
        .to eql(model.conversions_between(1.days.ago) / model.views_between(1.days.ago))

      expect(model.conversion_rate_between(Date.current))
        .to eql(model.conversions_between(Date.current) / model.views_between(Date.current))
    end
  end

  describe '#conversion_percent_between' do
    it 'returns proportion of conversion/views' do
      expect(model.conversion_percent_between(2.days.ago, 1.day.ago))
        .to eql(model.conversion_rate_between(2.days.ago, 1.day.ago) * 100)

      expect(model.conversion_percent_between(1.day.ago))
        .to eql(model.conversion_rate_between(1.day.ago) * 100)

      expect(model.conversion_percent_between(Date.current))
        .to eql(model.conversion_rate_between(Date.current) * 100)
    end
  end
end
