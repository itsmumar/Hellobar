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
