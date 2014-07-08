require 'spec_helper'

describe Rule do
  describe "#to_sentence" do
    it "says 'everyone' when there are no conditions" do
      Rule.new.to_sentence.should == "everyone"
    end

    it "concatenates conditions when present" do
      rule = Rule.new
      rule.conditions << UrlCondition.include_url("zombo.com")
      rule.to_sentence.should == "URL includes zombo.com"

      rule.conditions << UrlCondition.exclude_url("zombo.com/foo")
      rule.to_sentence.should == "URL includes zombo.com and URL does not include zombo.com/foo"

      rule.conditions << DateCondition.from_params("7/6", "")
      rule.to_sentence.should == "URL includes zombo.com, URL does not include zombo.com/foo, and date is after 7/6"
    end
  end

  describe 'accepting nested condition attributes' do
    it 'builds out a "before" date condition properly'
    it 'builds out an "after" date condition properly'
    it 'builds out a "between" date condition properly'
  end
end
