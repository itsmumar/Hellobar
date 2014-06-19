require 'spec_helper'

describe UrlCondition, '.create_include_url' do
  it 'creates the correct url condition with the correct operand' do
    url = 'http://googley.com'

    UrlCondition.should_receive(:create).
      with({ operand: Condition::OPERANDS[:includes], value: { 'include_url' => url } })

    UrlCondition.create_include_url(url)
  end
end

describe UrlCondition, '.create_exclude_url' do
  it 'creates the correct url condition with the correct operand' do
    url = 'http://moogley.com'

    UrlCondition.should_receive(:create).
      with({ operand: Condition::OPERANDS[:excludes], value: { 'exclude_url' => url } })

    UrlCondition.create_exclude_url(url)
  end
end

describe UrlCondition, '#url' do
  it 'returns the include_url if present' do
    condition = UrlCondition.new value: { 'include_url' => 'include' }

    condition.url.should == 'include'
  end

  it 'returns the exclude_url if present' do
    condition = UrlCondition.new value: { 'exclude_url' => 'exclude' }

    condition.url.should == 'exclude'
  end
  it 'returns nil when neither include_url nor exclude_url are present' do
    UrlCondition.new.url.should be_nil
  end
end
