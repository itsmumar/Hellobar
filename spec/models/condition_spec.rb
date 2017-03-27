RSpec.describe Condition, type: :model do
  it_behaves_like 'a model triggering script regeneration'

  describe '#validating the value format' do
    it 'clears empty values during validation' do
      condition = Condition.new(
        rule: create(:rule),
        operand: 'is',
        value: ['/foo', '/bar', ''],
        segment: 'UrlCondition'
      )

      expect(condition).to be_valid
      expect(condition.value).to eq(['/foo', '/bar'])
    end

    context 'the operand is NOT "between"' do
      it 'is NOT valid when the value is a non-String object' do
        condition = Condition.new operand: 'is', value: ['array'], rule: Rule.new

        expect(condition).not_to be_valid
      end

      it 'is valid when the value is a String' do
        condition = Condition.new operand: 'is', value: 'string', rule: Rule.new

        expect(condition).to be_valid
      end
    end

    context 'the operand is "between"' do
      it 'is NOT valid when the value is a non-Array object' do
        condition = Condition.new operand: 'between', value: 'string value', rule: Rule.new

        expect(condition).not_to be_valid
      end

      it 'is NOT valid when the value is an Array with 1 element' do
        condition = Condition.new operand: 'between', value: ['one'], rule: Rule.new

        expect(condition).not_to be_valid
      end

      it 'is NOT valid when the value is an array with 2 empty values' do
        condition = Condition.new operand: 'between', value: ['', ''], rule: Rule.new

        expect(condition).not_to be_valid
      end

      it 'is valid when the value is an Array with 2 elements' do
        condition = Condition.new operand: 'between', value: ['one', 'two'], rule: Rule.new

        expect(condition).to be_valid
      end
    end
  end

  describe '#date_condition_from_params' do
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
    context 'is a UrlCondition' do
      it 'calls #url_condition_sentence' do
        condition = create(:condition, operand: 'is', segment: 'UrlCondition', value: ['http://www.wee.com'])

        expect(condition).to receive(:multiple_condition_sentence) { 'right' }
        expect(condition.to_sentence).to eql('right')
      end
    end

    context 'is a UrlPathCondition' do
      it 'calls #url_condition_sentence' do
        condition = create(:condition, operand: 'is', segment: 'UrlPathCondition', value: ['/path/to/page'])

        expect(condition).to receive(:multiple_condition_sentence) { 'right' }
        expect(condition.to_sentence).to eql('right')
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
        condition = create(:condition, operand: 'every', segment: 'EveryXSession', value: '5')
        expect(condition.to_sentence).to eq('Every 5th session')
      end
    end

    context 'is a CustomCondition' do
      it "converts 'is between' conditions to sentences" do
        condition = create(:condition, operand: 'between', segment: 'CustomCondition', custom_segment: 'ABC', value: ['7/6', '7/13'])
        expect(condition.to_sentence).to eq('ABC is between 7/6 and 7/13')
      end

      it 'displays the name, operand and value' do
        condition = create(:condition, operand: 'is_not', segment: 'CustomCondition', custom_segment: 'ABC', value: '4')
        expect(condition.to_sentence).to eq('ABC is not 4')
      end
    end
  end

  describe '#normalize_url_condition' do
    context 'is not a UrlCondition' do
      it 'should do nothing to the value' do
        condition = build(:condition, segment: 'ReferrerCondition', value: 'google.com')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('google.com')
      end
    end

    context 'is a UrlCondition' do
      it 'should do nothing if url is already absolute (http)' do
        condition = build(:condition, segment: 'UrlCondition', value: 'http://google.com')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('http://google.com')
      end

      it 'should do nothing if url is already absolute (https)' do
        condition = build(:condition, segment: 'UrlCondition', value: 'https://google.com')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('https://google.com')
      end

      it 'should do nothing if url is already relative' do
        condition = build(:condition, segment: 'UrlCondition', value: '/about')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('/about')
      end

      it 'should prepend a / if url is relative' do
        condition = build(:condition, segment: 'UrlCondition', value: 'about')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('/about')
      end

      it 'should prepend a / if url is relative and has an extension' do
        condition = build(:condition, segment: 'UrlCondition', value: 'about.html')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('/about.html')
      end

      it 'should prepend http if url is absolute' do
        condition = build(:condition, segment: 'UrlCondition', value: 'about.com')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('http://about.com')
      end

      it 'should prepend http if url is absolute' do
        condition = build(:condition, segment: 'UrlCondition', value: 'hey.hellobar.com')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('http://hey.hellobar.com')
      end

      it 'should normalize values in an array' do
        condition = build(:condition, segment: 'UrlCondition', value: ['hey.hellobar.com', 'about.html'])
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq(['http://hey.hellobar.com', '/about.html'])
      end
    end

    context 'is a UrlPathCondition' do
      it 'should do nothing if url is already relative' do
        condition = build(:condition, segment: 'UrlPathCondition', value: '/about')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('/about')
      end

      it 'should prepend a / if url is relative' do
        condition = build(:condition, segment: 'UrlPathCondition', value: 'about')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('/about')
      end

      it 'should prepend a / if url is relative and has an extension' do
        condition = build(:condition, segment: 'UrlPathCondition', value: 'about.html')
        condition.send(:normalize_url_condition)
        expect(condition.value).to eq('/about.html')
      end
    end
  end

  describe '#format_string_values' do
    it 'it strips whitespace from string values' do
      condition = build(:condition, segment: 'ReferrerCondition', value: '  abc  ')
      condition.send(:format_string_values)
      expect(condition.value).to eq('abc')
    end

    it 'it strips whitespace from strings in the value array' do
      condition = build(:condition, segment: 'ReferrerCondition', value: ['  abc  '])
      condition.send(:format_string_values)
      expect(condition.value[0]).to eq('abc')
    end

    it 'does nothing when value is not a string or array' do
      condition = build(:condition, segment: 'ReferrerCondition', value: 1)
      condition.send(:format_string_values)
      expect(condition.value).to eq(1)
    end
  end
end

describe Condition, '#timezone_offset' do
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
