require 'spec_helper'

describe Rule, "#to_sentence" do
  it "says 'everyone' when there are no conditions" do
    Rule.new.to_sentence.should == "Show this to everyone"
  end

  it "concatenates conditions when present" do
    rule = Rule.new
    rule.conditions << UrlCondition.new(operand: :includes, value: "zombo.com")
    rule.to_sentence.should == "Show this when Page URL includes zombo.com"

    rule.conditions << UrlCondition.new(operand: :does_not_include, value: "zombo.com/foo")
    rule.to_sentence.should == "Show this when Page URL includes zombo.com and Page URL does not include zombo.com/foo"

    rule.conditions << DateCondition.from_params("7/6", "")
    rule.to_sentence.should == "Show this when Page URL includes zombo.com, Page URL does not include zombo.com/foo, and Date is after 7/6"
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

  it 'builds out a URL condition with a string' do
    condition = conditions(:url_includes)
    expect(condition.value.class).to eq(String)
    expect(condition.value).to eq("/asdf")
    expect(condition.to_sentence).to eq "Page URL includes /asdf"
  end

  it 'builds out a URL condition with a string' do
    condition = conditions(:url_does_not_include)
    expect(condition.value.class).to eq(String)
    expect(condition.value).to eq("/asdf")
    expect(condition.to_sentence).to eq "Page URL does not include /asdf"
  end
end
