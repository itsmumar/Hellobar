FactoryGirl.define do
  factory :condition do
    rule
    operand 'is'
    segment 'UrlCondition'
    value ['http://test.com']

    trait :url_is

    trait :url_includes do
      operand 'includes'
      segment 'UrlCondition'
      value ['/asdf']
    end

    trait :url_does_not_include do
      operand 'does_not_include'
      segment 'UrlCondition'
      value ['/asdf']
    end

    trait :date_between do
      segment 'DateCondition'
      operand 'between'
      value { [Date.yesterday.strftime('%Y-%m-%d'), Date.tomorrow.strftime('%Y-%m-%d')] }
    end

    trait :date_before do
      segment 'DateCondition'
      operand 'before'
      value { Date.tomorrow.strftime('%Y-%m-%d') }
    end

    trait :date_after do
      segment 'DateCondition'
      operand 'after'
      value { Date.yesterday.strftime('%Y-%m-%d') }
    end

    trait :mobile do
      segment 'DeviceCondition'
      operand 'is'
      value 'mobile'
    end
  end
end
