describe ChartDataSerializer, freeze: '2017-01-10' do
  let(:site_statistics) { create :site_statistics, views: Array.new(3, 1) }
  let(:type) { :total }
  let(:days) {}
  let(:serializer) { ChartDataSerializer.new(site_statistics, days: days, type: type) }

  describe '#as_json' do
    context 'with days limit' do
      let(:days) { 2 }

      it 'returns scope within days number' do
        expect(serializer.as_json).to eql([
          { date: '1/09', value: 2 },
          { date: '1/10', value: 3 }
        ])
      end
    end

    context 'without days limit' do
      let(:days) { '' }

      it 'returns whole scope' do
        expect(serializer.as_json).to eql([
          { date: '1/08', value: 1 },
          { date: '1/09', value: 2 },
          { date: '1/10', value: 3 }
        ])
      end
    end

    context 'when type is not :total' do
      let(:type) { :call }
      let(:site_statistics) do
        create :site_statistics,
          goal: type,
          views: Array.new(3, 2),
          conversions: Array.new(3, 1)
      end

      it 'returns conversions as value' do
        expect(serializer.as_json).to eql([
          { date: '1/08', value: 1 },
          { date: '1/09', value: 2 },
          { date: '1/10', value: 3 }
        ])
      end
    end
  end
end
