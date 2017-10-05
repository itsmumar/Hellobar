FactoryGirl.define do
  factory :condition do
    rule

    segment 'UrlCondition'
    operand 'is'
    value ['http://test.com']

    trait :url

    trait :url_includes do
      segment 'UrlCondition'
      operand 'includes'
      value ['/asdf']
    end

    trait :url_does_not_include do
      segment 'UrlCondition'
      operand 'does_not_include'
      value ['/asdf']
    end

    trait :url_path do
      segment 'UrlCondition'
      operand 'is'
      value ['/path']
    end

    trait :every_x_session do
      segment 'EveryXSession'
      operand 'every'
      value '2'
    end

    trait :referrer do
      segment 'ReferrerCondition'
      operand 'is'
      value 'https://google.com'
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

    trait :time_before do
      segment 'TimeCondition'
      operand 'before'
      value { %w[09 00 America/Los_Angeles] }
    end

    trait :mobile do
      segment 'DeviceCondition'
      operand 'is'
      value 'mobile'
    end

    trait :url_query do
      segment 'UrlQueryCondition'
      operand 'includes'
      value 'a=b'
    end

    trait :utm_source do
      segment 'UTMSourceCondition'
      operand 'is'
      value 'hellobar'
    end
  end
end
