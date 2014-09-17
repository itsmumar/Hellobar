require 'spec_helper'

describe UrlCondition, '::include_url' do
  it 'creates the correct url condition with the correct operand' do
    url = 'http://googley.com'

    UrlCondition.should_receive(:new).
      with({ operand: :includes, value: url })

    UrlCondition.include_url(url)
  end
end

describe UrlCondition, '::does_not_include' do
  it 'creates the correct url condition with the correct operand' do
    url = 'http://moogley.com'

    UrlCondition.should_receive(:new).
      with({ operand: :does_not_include, value: url })

    UrlCondition.does_not_include_url(url)
  end
end

describe UrlCondition, '#include_url?' do
  it 'returns true when the operator is includes' do
    condition = UrlCondition.new operand: :includes

    condition.should be_include_url
  end

  it 'returns false when the operator is not includes' do
    UrlCondition.new.should_not be_include_url
  end
end

describe UrlCondition, '#to_sentence' do
  it "converts does_not_include urls conditions to sentences" do
    UrlCondition.does_not_include_url("zombo.com").to_sentence.should == "URL does not include zombo.com"
  end

  it "converts include url conditions to sentences" do
    UrlCondition.include_url("zombo.com").to_sentence.should == "URL includes zombo.com"
  end
end
