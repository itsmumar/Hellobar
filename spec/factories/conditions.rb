FactoryGirl.define do
  factory :condition do
    rule
    operand 'is'
    segment 'UrlCondition'
    value ['http://test.com']

    trait :url_includes do
      operand 'includes'
      segment 'UrlCondition'
      value ['/asdf']
    end

    trait :date_between do
      segment 'DateCondition'
      operand 'between'
      value ['2017-03-12', '2017-03-14']
    end

    trait :date_before do
      segment 'DateCondition'
      operand 'between'
      value ['2017-03-12', '2017-03-14']
    end
  end
end
