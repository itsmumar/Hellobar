describe BarStatistics, freeze: '2017-01-03' do
  let(:model) { BarStatistics.new }

  before do
    model << { 'v' => 100, 'c' => 10, 'date' => Date.today - 2, 'sid' => 1 }
    model << { 'v' => 100, 'c' => 10, 'date' => Date.today - 1, 'sid' => 1 }
    model << { 'v' => 100, 'c' => 10, 'date' => Date.today, 'sid' => 1 }
  end

  describe '#views' do
    it 'sums all views' do
      expect(model.views).to eql 300
      expect(model.views(1.day.ago)).to eql 200
      expect(model.views(2.day.ago)).to eql 100
    end
  end

  describe '#conversions' do
    it 'sums all conversions' do
      expect(model.conversions).to eql 30
      expect(model.conversions(1.day.ago)).to eql 20
      expect(model.conversions(2.day.ago)).to eql 10
    end
  end

  describe '#views_between' do
    it 'sums views' do
      expect(model.views_between(2.day.ago, 1.day.ago)).to eql 200
      expect(model.views_between(1.day.ago)).to eql 200
      expect(model.views_between(Date.today)).to eql 100
    end
  end

  describe '#conversions_between' do
    it 'sums conversions' do
      expect(model.conversions_between(2.day.ago, 1.day.ago)).to eql 20
      expect(model.conversions_between(1.day.ago)).to eql 20
      expect(model.conversions_between(Date.today)).to eql 10
    end
  end

  describe '#conversion_percent_between' do
    it 'returns proportion of conversion/views' do
      expect(model.conversion_percent_between(2.day.ago, 1.day.ago)).to eql 0.1
      expect(model.conversion_percent_between(1.day.ago)).to eql 0.1
      expect(model.conversion_percent_between(Date.today)).to eql 0.1
    end
  end
end
