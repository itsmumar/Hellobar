require 'spec_helper'

describe Rule, "#to_sentence" do
  it "says 'everyone' when there are no conditions" do
    Rule.new.to_sentence.should == "Show this to everyone"
  end

  it "concatenates conditions when present" do
    rule = Rule.new
    rule.conditions << Condition.new(operand: :includes, value: ["zombo.com"], segment: "UrlCondition")
    rule.to_sentence.should == "Page URL includes zombo.com"

    rule.conditions << Condition.new(operand: :does_not_include, value: ["zombo.com/foo"], segment: "UrlCondition")
    rule.to_sentence.should == "Page URL includes zombo.com and 1 other condition"

    rule.conditions << Condition.date_condition_from_params("7/6", "")
    rule.to_sentence.should == "Page URL includes zombo.com and 2 other conditions"
  end
end

describe Rule, 'accepting nested condition attributes' do
  fixtures :all

  let(:rule) { rules(:zombo) }
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
    expect(condition.to_sentence).to eq "Page URL includes /foo or 1 other URL"
  end

  it 'builds out a URL condition with > 2 URLs' do
    condition = conditions(:url_includes)
    condition.value = ["/foo", "/bar", "/baz"]
    expect(condition.to_sentence).to eq "Page URL includes /foo or 2 other URLs"
  end
end

describe Rule, "#same_as?" do
  fixtures :all

  let(:rule) { rules(:zombo) }
  let(:other_rule) { rules(:zombo).clone }
  let(:site) { sites(:zombo) }

  it "returns true if neither rule has conditions" do
    rule.conditions.any?.should be_false
    other_rule.conditions.any?.should be_false

    rule.should be_same_as(other_rule)
  end

  it "returns true if both rules have the same conditions" do
    rule.stub(conditions: [conditions(:date_between)])
    other_rule.stub(conditions: [conditions(:date_between)])

    rule.should be_same_as(other_rule)
  end

  it "returns true if the rules' \"match\" values are different, but there is only one rule" do
    rule.stub(match: "any", conditions: [conditions(:date_between)])
    other_rule.stub(match: "all", conditions: [conditions(:date_between)])

    rule.should be_same_as(other_rule)
  end

  it "returns false if the rules' \"match\" values are different and there is more than one rule" do
    rule.stub(match: "any", conditions: [conditions(:date_between), conditions(:date_after)])
    other_rule.stub(match: "all", conditions: [conditions(:date_between), conditions(:date_after)])

    rule.should_not be_same_as(other_rule)
  end
end

describe Rule, "::create_from_segment" do
  fixtures :all

  let(:site) { sites(:zombo) }

  it "creates a rule with the correct conditions" do
    rule = Rule.create_from_segment(site, "dv:mobile")
    condition = rule.conditions.first

    rule.should be_valid
    rule.conditions.count.should == 1

    condition.segment.should == "DeviceCondition"
    condition.value.should == "mobile"
    condition.operand.should == "is"
  end

  it "creates a url condition" do
    rule = Rule.create_from_segment(site, "pu:httpsomeurl")
    condition = rule.conditions.first

    rule.should be_valid
    rule.conditions.count.should == 1

    condition.segment.should == "UrlCondition"
    condition.value.should == ["httpsomeurl"]
    condition.operand.should == "is"
  end

  it "sets the name based on segment" do
    rule = Rule.create_from_segment(site, "dv:mobile")
    rule.name.should == "Device is mobile"
  end
end
