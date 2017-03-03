require 'spec_helper'

describe Rule do
  it_behaves_like 'a model triggering script regeneration'

  describe ".defaults" do
    let(:defaults)         { Rule.defaults }
    let(:everyone)         { defaults[0] }
    let(:mobile)           { defaults[1] }
    let(:homepage)         { defaults[2] }

    it "creates new unsaved rules" do
      defaults.each do |rule|
        expect(rule).to be_new_record
      end
    end

    it "sets the default rule names" do
      expect(everyone.name).to eq("Everyone")
      expect(mobile.name).to eq("Mobile Visitors")
      expect(homepage.name).to eq("Homepage Visitors")
    end

    it "matches all" do
      defaults.each do |rule|
        expect(rule.match).to eq(Rule::MATCH_ON[:all])
      end
    end

    it "is not editable" do
      defaults.each do |rule|
        expect(rule.editable).to be_false
      end
    end

    describe "mobile rule" do
      let(:mobile_condition) { mobile.conditions[0]}

      it "sets conditions" do
        expect(mobile.conditions.size).to eq(1)
      end

      it "sets the mobile rule's condition to filter for mobile traffic" do
        expect(mobile_condition.segment).to eq("DeviceCondition")
        expect(mobile_condition.operand).to eq("is")
        expect(mobile_condition.value).to eq("mobile")
      end
    end

    describe "homepage rule" do
      let(:homepage_condition) { homepage.conditions[0]}

      it "sets conditions" do
        expect(homepage.conditions.size).to eq(1)
      end

      it "sets the mobile rule's condition to filter for mobile traffic" do
        expect(homepage_condition.segment).to eq("UrlPathCondition")
        expect(homepage_condition.operand).to eq("is")
        expect(homepage_condition.value).to eq(["/"])
      end
    end
  end

  describe "#to_sentence" do
    it "says 'everyone' when there are no conditions" do
      expect(Rule.new.to_sentence).to eq("Show this to everyone")
    end

    it "concatenates conditions when present" do
      rule = Rule.new
      rule.conditions << Condition.new(operand: :includes, value: ["zombo.com"], segment: "UrlCondition")
      expect(rule.to_sentence).to eq("Page URL includes zombo.com")

      rule.conditions << Condition.new(operand: :does_not_include, value: ["zombo.com/foo"], segment: "UrlCondition")
      expect(rule.to_sentence).to eq("Page URL includes zombo.com and 1 other condition")

      rule.conditions << Condition.date_condition_from_params("7/6", "")
      expect(rule.to_sentence).to eq("Page URL includes zombo.com and 2 other conditions")
    end
  end

  describe 'accepting nested condition attributes' do
    fixtures :all

    let(:rule) { rules(:zombo_rule) }
    let(:site) { sites(:zombo) }

    before do
      expect(rule).to be_present
      expect(rule.conditions).to be_empty
    end

    it 'builds out a "before" date condition properly' do
      condition = conditions(:date_before)
      tomorrow = Date.tomorrow.strftime("%Y-%m-%d")

      expect(condition.value).to eq tomorrow
      expect(condition.to_sentence).to eq "Date is before #{tomorrow}"
    end

    it 'builds out an "after" date condition properly' do
      condition = conditions(:date_after)
      yesterday = Date.yesterday.strftime("%Y-%m-%d")

      expect(condition.value).to eq yesterday
      expect(condition.to_sentence).to eq "Date is after #{yesterday}"
    end

    it 'builds out a "between" date condition properly' do
      condition = conditions(:date_between)
      yesterday = Date.yesterday.strftime("%Y-%m-%d")
      tomorrow = Date.tomorrow.strftime("%Y-%m-%d")

      expect(condition.value).to eq [yesterday, tomorrow]
    end

    it 'builds out a URL condition with an include URLs' do
      condition = conditions(:url_includes)
      expect(condition.value.class).to eq(Array)
      expect(condition.value).to eq(["/asdf"])
      expect(condition.to_sentence).to eq "Page URL includes /asdf"
    end

    it 'builds out a URL condition with a "does not include" URL' do
      condition = conditions(:url_does_not_include)
      expect(condition.value.class).to eq(Array)
      expect(condition.value).to eq(["/asdf"])
      expect(condition.to_sentence).to eq "Page URL does not include /asdf"
    end

    it 'builds out a URL condition with 2 URLs' do
      condition = conditions(:url_includes)
      condition.value = ["/foo", "/bar"]
      expect(condition.to_sentence).to eq "Page URL includes /foo or 1 other"
    end

    it 'builds out a URL condition with > 2 URLs' do
      condition = conditions(:url_includes)
      condition.value = ["/foo", "/bar", "/baz"]
      expect(condition.to_sentence).to eq "Page URL includes /foo or 2 others"
    end
  end

  describe "#same_as?" do
    fixtures :all

    let(:rule) { rules(:zombo_rule) }
    let(:other_rule) { rules(:zombo_rule).clone }
    let(:site) { sites(:zombo) }

    it "returns true if neither rule has conditions" do
      expect(rule.conditions.any?).to be_false
      expect(other_rule.conditions.any?).to be_false

      expect(rule).to be_same_as(other_rule)
    end

    it "returns true if both rules have the same conditions" do
      rule.stub(conditions: [conditions(:date_between)])
      other_rule.stub(conditions: [conditions(:date_between)])

      expect(rule).to be_same_as(other_rule)
    end

    it "returns true if the rules' \"match\" values are different, but there is only one rule" do
      rule.stub(match: "any", conditions: [conditions(:date_between)])
      other_rule.stub(match: "all", conditions: [conditions(:date_between)])

      expect(rule).to be_same_as(other_rule)
    end

    it "returns false if the rules' \"match\" values are different and there is more than one rule" do
      rule.stub(match: "any", conditions: [conditions(:date_between), conditions(:date_after)])
      other_rule.stub(match: "all", conditions: [conditions(:date_between), conditions(:date_after)])

      expect(rule).not_to be_same_as(other_rule)
    end
  end

  describe ".create_from_segment" do
    fixtures :all

    let(:site) { sites(:zombo) }

    it "creates a rule with the correct conditions" do
      rule = Rule.create_from_segment(site, "dv:mobile")
      condition = rule.conditions.first

      expect(rule).to be_valid
      expect(rule.conditions.count).to eq(1)

      expect(condition.segment).to eq("DeviceCondition")
      expect(condition.value).to eq("mobile")
      expect(condition.operand).to eq("is")
    end

    it "creates a url condition" do
      rule = Rule.create_from_segment(site, "pu:httpsomeurl")
      condition = rule.conditions.first

      expect(rule).to be_valid
      expect(rule.conditions.count).to eq(1)

      expect(condition.segment).to eq("UrlCondition")
      expect(condition.value).to eq(["/httpsomeurl"])
      expect(condition.operand).to eq("is")
    end

    it "sets the name based on segment" do
      rule = Rule.create_from_segment(site, "dv:mobile")
      expect(rule.name).to eq("Device is mobile")
    end
  end
end
