describe Condition do
  it { is_expected.to validate_presence_of :rule }
  it { is_expected.to validate_presence_of :segment }
  it { is_expected.to validate_inclusion_of(:segment).in_array Condition::SEGMENTS.keys }
  it { is_expected.to validate_presence_of :operand }
  it { is_expected.to validate_presence_of :value }

  describe '#validating the value format' do
    it 'clears empty values during validation' do
      condition = Condition.new(
        rule: create(:rule),
        operand: 'is',
        value: ['/foo', '/bar', ''],
        segment: 'UrlPathCondition'
      )

      expect(condition).to be_valid
      expect(condition.value).to eq(['/foo', '/bar'])
    end

    context 'the operand is NOT "between"' do
      it 'is NOT valid when the value is a non-String object' do
        condition = Condition.new segment: 'DeviceCondition', operand: 'is',
          value: ['array'], rule: Rule.new

        expect(condition).not_to be_valid
      end

      it 'is valid when the value is a String' do
        condition = Condition.new segment: 'DeviceCondition', operand: 'is',
          value: 'string', rule: Rule.new

        expect(condition).to be_valid
      end
    end

    context 'the operand is "between"' do
      it 'is NOT valid when the value is a non-Array object' do
        condition = Condition.new segment: 'DateCondition', operand: 'between',
          value: 'string value', rule: Rule.new

        expect(condition).not_to be_valid
      end

      it 'is NOT valid when the value is an Array with 1 element' do
        condition = Condition.new segment: 'LastVisitCondition', operand: 'between',
          value: ['one'], rule: Rule.new

        expect(condition).not_to be_valid
      end

      it 'is NOT valid when the value is an array with 2 empty values' do
        condition = Condition.new segment: 'LastVisitCondition', operand: 'between',
          value: ['', ''], rule: Rule.new

        expect(condition).not_to be_valid
      end

      it 'is valid when the value is an Array with 2 elements' do
        condition = Condition.new segment: 'LastVisitCondition', operand: 'between',
          value: ['one', 'two'], rule: Rule.new

        expect(condition).to be_valid
      end
    end
  end

  describe '.date_condition_from_params' do
    it 'creates a between condition when both start_date and end_date are present' do
      condition = Condition.date_condition_from_params('start', 'end')

      expect(condition.operand).to eq('between')
      expect(condition.value).to eq(['start', 'end'])
    end

    it 'creates a start_date condition when only start_date is present' do
      condition = Condition.date_condition_from_params('start', '')

      expect(condition.operand).to eq('after')
      expect(condition.value).to eq('start')
    end

    it 'creates a end_date condition when only end_date is present' do
      condition = Condition.date_condition_from_params('', 'end')

      expect(condition.operand).to eq('before')
      expect(condition.value).to eq('end')
    end

    it 'does nothing when neither start nor end date are present' do
      expect(Condition.date_condition_from_params('', '')).to be_nil
    end
  end

  describe '#to_sentence' do
    context 'is a UrlPathCondition' do
      it 'calls #url_condition_sentence' do
        condition = create :condition, :url_path

        expect(condition).to be_persisted
        expect(condition).to receive(:multiple_condition_sentence) { 'right' }
        expect(condition.to_sentence).to eql('right')
      end
    end

    context 'is a UrlQueryCondition' do
      it 'outputs nice sentence' do
        condition = create :condition, :url_query

        expect(condition).to be_persisted
        expect(condition.to_sentence).to include 'Page Query'
      end
    end

    context 'is a DateCondition' do
      it "converts 'is between' conditions to sentences" do
        expect(Condition.date_condition_from_params('7/6', '7/13').to_sentence).to eq('Date is between 7/6 and 7/13')
      end

      it "converts 'is before' conditions to sentences" do
        expect(Condition.date_condition_from_params('', '7/13').to_sentence).to eq('Date is before 7/13')
      end

      it "converts 'is after' conditions to sentences" do
        expect(Condition.date_condition_from_params('7/6', '').to_sentence).to eq('Date is after 7/6')
      end
    end

    context 'is a EveryXSession' do
      it 'ordinalizes the value' do
        condition = create :condition, :every_x_session, value: '5'

        expect(condition).to be_persisted
        expect(condition.to_sentence).to eq('Every 5th session')
      end
    end

    context 'is a DaysOfWeekCondition' do
      it 'ordinalizes the value' do
        condition = create :condition, :days_of_week, value: ['2'], rule: Rule.new

        expect(condition).to be_valid
        expect(condition.to_sentence).to eq('Days of the week is Tuesday')
      end
    end

    context 'is a UTMSourceCondition' do
      it 'outputs nice sentence' do
        condition = create :condition, :utm_source

        expect(condition).to be_persisted
        expect(condition.to_sentence).to include 'Ad Source'
      end
    end
  end

  describe '#normalize_url_condition' do
    context 'is not a UrlPathCondition' do
      it 'should do nothing to the value' do
        value = 'https://google.com'
        condition = build :condition, :referrer, value: value

        condition.send(:normalize_url_condition)
        expect(condition.value).to eq value
      end
    end

    context 'is a UrlPathCondition' do
      it 'should do nothing if url is already relative' do
        path = '/about'
        condition = build(:condition, :url_path, value: path)
        condition.send(:normalize_url_condition)

        expect(condition.value).to eq path
      end

      it 'should prepend a / if url is relative' do
        path = 'about'
        condition = build(:condition, :url_path, value: path)
        condition.send(:normalize_url_condition)

        expect(condition.value).to eq "/#{ path }"
      end

      it 'should prepend a / if url is relative and has an extension' do
        path = 'about.html'
        condition = build(:condition, :url_path, value: path)
        condition.send(:normalize_url_condition)

        expect(condition.value).to eq "/#{ path }"
      end
    end
  end

  describe '#format_string_values' do
    it 'it strips whitespace from string values' do
      referrer = '  abc  '
      condition = build(:condition, :referrer, value: referrer)
      condition.send(:format_string_values)

      expect(condition.value).to eq referrer.strip
    end

    it 'it strips whitespace from strings in the value array' do
      referrer = '  abc  '
      condition = build(:condition, :referrer, value: [referrer])
      condition.send(:format_string_values)

      expect(condition.value.first).to eq referrer.strip
    end

    it 'does nothing when value is not a string or array' do
      referrer = 1
      condition = build(:condition, :referrer, value: referrer)
      condition.send(:format_string_values)

      expect(condition.value).to eq referrer
    end
  end

  describe '#timezone_offset' do
    let(:condition) { Condition.new(segment: 'TimeCondition') }

    it 'returns nil if the condition is not a TimeCondition' do
      condition.segment = 'not time condition'

      expect(condition.timezone_offset).to be_nil
    end

    it 'returns visitor if the condition is set to user the visitors timezone' do
      condition.value = [1, 2, 'visitor']

      expect(condition.timezone_offset).to eql('visitor')
    end

    it 'returns the correct timezone offset when a TimeCondition and has the timezone set' do
      condition.value = [1, 2, 'America/Chicago']

      expected_offset = Time.use_zone('America/Chicago') do
        Time.zone.now.formatted_offset
      end

      expect(condition.timezone_offset).to eql(expected_offset)
    end
  end

  describe '#serialized_value' do
    let(:condition) { build :condition }

    context 'when segment key is "gl_ctr"' do
      before { condition.segment = 'LocationCountryCondition' }

      context 'and value includes "EU"' do
        before { condition.value = ['US', 'EU'] }

        it 'adds all EU countries to the value' do
          expect(condition.serialized_value).to include(*Condition::EU_COUNTRIES)
          expect(condition.serialized_value).to include('US')
        end
      end

      context 'and does not include "EU"' do
        before { condition.value = ['US'] }

        it 'returns value' do
          expect(condition.serialized_value).to eql ['US']
        end
      end
    end

    context 'when segment key is not "gl_ctr"' do
      before { condition.value = ['US', 'EU'] }

      it 'returns value' do
        expect(condition.serialized_value).to eql(['US', 'EU'])
      end
    end
  end
end
