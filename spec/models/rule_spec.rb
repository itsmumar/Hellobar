describe Rule do
  describe '.defaults' do
    let(:defaults)         { Rule.defaults }
    let(:everyone)         { defaults[0] }
    let(:mobile)           { defaults[1] }
    let(:homepage)         { defaults[2] }

    it 'creates new unsaved rules' do
      defaults.each do |rule|
        expect(rule).to be_new_record
      end
    end

    it 'sets the default rule names' do
      expect(everyone.name).to eq('Everyone')
      expect(mobile.name).to eq('Mobile Visitors')
      expect(homepage.name).to eq('Homepage Visitors')
    end

    it 'matches all' do
      defaults.each do |rule|
        expect(rule.match).to eq(Rule::MATCH_ON[:all])
      end
    end

    it 'is not editable' do
      defaults.each do |rule|
        expect(rule.editable).to be_falsey
      end
    end

    describe 'mobile rule' do
      let(:mobile_condition) { mobile.conditions[0] }

      it 'sets conditions' do
        expect(mobile.conditions.size).to eq(1)
      end

      it "sets the mobile rule's condition to filter for mobile traffic" do
        expect(mobile_condition.segment).to eq('DeviceCondition')
        expect(mobile_condition.operand).to eq('is')
        expect(mobile_condition.value).to eq('mobile')
      end
    end

    describe 'homepage rule' do
      let(:homepage_condition) { homepage.conditions[0] }

      it 'sets conditions' do
        expect(homepage.conditions.size).to eq(1)
      end

      it "sets the mobile rule's condition to filter for mobile traffic" do
        expect(homepage_condition.segment).to eq('UrlPathCondition')
        expect(homepage_condition.operand).to eq('is')
        expect(homepage_condition.value).to eq(['/'])
      end
    end
  end

  describe '#to_sentence' do
    it "says 'everyone' when there are no conditions" do
      expect(Rule.new.to_sentence).to eq('Show this to everyone')
    end

    it 'concatenates conditions when present' do
      rule = Rule.new
      rule.conditions << build(:condition, :url_path_includes, value: ['/foo'])
      expect(rule.to_sentence).to eq('URL Path includes /foo')

      rule.conditions << build(:condition, :url_path_does_not_include, value: ['/bar'])
      expect(rule.to_sentence).to eq('URL Path includes /foo and 1 other condition')

      rule.conditions << Condition.date_condition_from_params('7/6', '')
      expect(rule.to_sentence).to eq('URL Path includes /foo and 2 other conditions')
    end
  end

  describe 'accepting nested condition attributes' do
    let(:rule) { create(:rule) }
    let(:site) { create(:site) }

    before do
      expect(rule).to be_present
      expect(rule.conditions).to be_empty
    end

    it 'builds out a "before" date condition properly' do
      condition = create(:condition, :date_before)
      tomorrow = Date.tomorrow.strftime('%Y-%m-%d')

      expect(condition.value).to eq tomorrow
      expect(condition.to_sentence).to eq "Date is before #{ tomorrow }"
    end

    it 'builds out an "after" date condition properly' do
      condition = create(:condition, :date_after)
      yesterday = Date.yesterday.strftime('%Y-%m-%d')

      expect(condition.value).to eq yesterday
      expect(condition.to_sentence).to eq "Date is after #{ yesterday }"
    end

    it 'builds out a "between" date condition properly' do
      condition = create(:condition, :date_between)
      yesterday = Date.yesterday.strftime('%Y-%m-%d')
      tomorrow = Date.tomorrow.strftime('%Y-%m-%d')

      expect(condition.value).to eq [yesterday, tomorrow]
    end

    it 'builds out a URL condition with an include URL path' do
      condition = create(:condition, :url_path_includes)
      expect(condition.value.class).to eq(Array)
      expect(condition.value).to eq(['/asdf'])
      expect(condition.to_sentence).to eq 'URL Path includes /asdf'
    end

    it 'builds out a URL condition with a "does not include" URL' do
      condition = create(:condition, :url_path_does_not_include)
      expect(condition.value.class).to eq(Array)
      expect(condition.value).to eq(['/asdf'])
      expect(condition.to_sentence).to eq 'URL Path does not include /asdf'
    end

    it 'builds out a URL condition with 2 URLs' do
      condition = create(:condition, :url_path_includes)
      condition.value = ['/foo', '/bar']
      expect(condition.to_sentence).to eq 'URL Path includes /foo or 1 other'
    end

    it 'builds out a URL condition with > 2 URLs' do
      condition = create(:condition, :url_path_includes)
      condition.value = ['/foo', '/bar', '/baz']
      expect(condition.to_sentence).to eq 'URL Path includes /foo or 2 others'
    end
  end

  describe '#same_as?' do
    let(:rule) { create(:rule) }
    let(:other_rule) { create(:rule) }
    let(:site) { create(:site) }
    let(:date_between) { create(:condition, :date_between) }
    let(:date_after) { create(:condition, :date_after) }

    it 'returns true if neither rule has conditions' do
      expect(rule.conditions.any?).to be_falsey
      expect(other_rule.conditions.any?).to be_falsey

      expect(rule).to be_same_as(other_rule)
    end

    it 'returns true if both rules have the same conditions' do
      allow(rule).to receive(:conditions).and_return([date_between])
      allow(other_rule).to receive(:conditions).and_return([date_between])

      expect(rule).to be_same_as(other_rule)
    end

    it 'returns true if the rules "match" values are different, but there is only one rule' do
      allow(rule).to receive(:match).and_return('any')
      allow(rule).to receive(:conditions).and_return([date_between])

      allow(other_rule).to receive(:match).and_return('all')
      allow(other_rule).to receive(:conditions).and_return([date_between])

      expect(rule).to be_same_as(other_rule)
    end

    it 'returns false if the rules "match" values are different and there is more than one rule' do
      allow(rule).to receive(:match).and_return('any')
      allow(rule).to receive(:conditions).and_return([date_between, date_after])

      allow(other_rule).to receive(:match).and_return('all')
      allow(other_rule).to receive(:conditions).and_return([date_between, date_after])

      expect(rule).not_to be_same_as(other_rule)
    end
  end

  describe '#nested_error_messages' do
    it 'includes errors on the Rule model' do
      rule = Rule.new site: Site.new

      rule.valid?

      expect(rule.nested_error_messages).to include "name can't be blank"
    end

    it 'includes errors on the nested model' do
      condition = Condition.new
      rule = Rule.new site: Site.new, name: 'Name', conditions: [condition]

      rule.valid?

      expect(rule.nested_error_messages).to include "segment can't be blank"
      expect(rule.nested_error_messages).to include 'segment is not included in the list'
      expect(rule.nested_error_messages).to include "operand can't be blank"
      expect(rule.nested_error_messages).to include "conditions value can't be blank"
    end
  end
end
