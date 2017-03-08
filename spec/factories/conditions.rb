FactoryGirl.define do
  factory :condition do
    rule
    operand 'is'
    segment 'UrlCondition'
    value ['http://test.com']
  end
end
