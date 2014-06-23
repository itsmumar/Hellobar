require 'spec_helper'

describe UrlCondition, '.create_include_url' do
  it 'creates the correct url condition with the correct operand' do
    url = 'http://googley.com'

    UrlCondition.should_receive(:create).
      with({ operand: Condition::OPERANDS[:includes], value: url })

    UrlCondition.create_include_url(url)
  end
end

describe UrlCondition, '.create_exclude_url' do
  it 'creates the correct url condition with the correct operand' do
    url = 'http://moogley.com'

    UrlCondition.should_receive(:create).
      with({ operand: Condition::OPERANDS[:excludes], value: url })

    UrlCondition.create_exclude_url(url)
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
