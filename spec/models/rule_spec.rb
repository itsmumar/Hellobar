require 'spec_helper'

describe Rule, "#to_sentence" do
  it "says 'everyone' when there are no conditions" do
    Rule.new.to_sentence.should == "Show this to everyone"
  end

  it "concatenates conditions when present" do
    rule = Rule.new
    rule.conditions << UrlCondition.include_url("zombo.com")
    rule.to_sentence.should == "Show this when URL includes zombo.com"

    rule.conditions << UrlCondition.exclude_url("zombo.com/foo")
    rule.to_sentence.should == "Show this when URL includes zombo.com and URL does not include zombo.com/foo"

    rule.conditions << DateCondition.from_params("7/6", "")
    rule.to_sentence.should == "Show this when URL includes zombo.com, URL does not include zombo.com/foo, and date is after 7/6"
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
    expect(condition.value.class).to eq(Hash)
    condition.value.tap do |hash|
      expect(hash['start_date']).to be_nil
      expect(hash['end_date']).to eq Date.current + 1.day
    end
    expect(condition.to_sentence).to eq "date is before #{Date.current + 1.day}"
  end

  it 'builds out an "after" date condition properly' do
    condition = conditions(:date_after)
    expect(condition.value.class).to eq(Hash)
    condition.value.tap do |hash|
      expect(hash['end_date']).to be_nil
      expect(hash['start_date']).to eq Date.current - 1.day
    end
    expect(condition.to_sentence).to eq "date is after #{Date.current - 1.day}"
  end

  it 'builds out a "between" date condition properly' do
    condition = conditions(:date_between)
    expect(condition.value.class).to eq(Hash)
    condition.value.tap do |hash|
      expect(hash['start_date']).to eq Date.current - 1.day
      expect(hash['end_date']).to eq Date.current + 1.day
    end
  end

  it 'builds out a URL condition with a string' do
    condition = conditions(:url_includes)
    expect(condition.value.class).to eq(String)
    expect(condition.value).to eq("/asdf")
    expect(condition.to_sentence).to eq "URL includes /asdf"
  end

  it 'builds out a URL condition with a string' do
    condition = conditions(:url_excludes)
    expect(condition.value.class).to eq(String)
    expect(condition.value).to eq("/asdf")
    expect(condition.to_sentence).to eq "URL does not include /asdf"
  end
end
