require 'spec_helper'

describe UrlCondition, '::include_url' do
  it 'creates the correct url condition with the correct operand' do
    url = 'http://googley.com'

    UrlCondition.should_receive(:new).
      with({ operand: Condition::OPERANDS[:includes], value: url })

    UrlCondition.include_url(url)
  end
end

describe UrlCondition, '::exclude_url' do
  it 'creates the correct url condition with the correct operand' do
    url = 'http://moogley.com'

    UrlCondition.should_receive(:new).
      with({ operand: Condition::OPERANDS[:excludes], value: url })

    UrlCondition.exclude_url(url)
  end
end

describe UrlCondition, '#include_url?' do
  it 'returns true when the operator is includes' do
    condition = UrlCondition.new operand: Condition::OPERANDS[:includes]

    condition.should be_include_url
  end

  it 'returns false when the operator is not includes' do
    UrlCondition.new.should_not be_include_url
  end
end
