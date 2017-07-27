FactoryGirl.define do
  factory :bar_statistics, class: BarStatistics do
    skip_create

    transient do
      first_date Date.current
      views []
      conversions []
    end

    initialize_with do
      records =
        views.zip(conversions).map.with_index do |(view, conversion), number|
          BarStatistics::Record.new(view || 0, conversion || 0, number.days.until(first_date).to_date)
        end
      BarStatistics.new records
    end

    trait :with_views do
      transient do
        views [1, 2, 3, 4]
      end
    end
  end

  factory :bar_statistics_record, class: OpenStruct do
    skip_create

    site_element
    views { 100 }
    conversions { 10 }
    date { '2017-01-01' }

    json do
      dt = Date.parse(date) if date
      {
        'v' => { 'N': views },
        'c' => { 'N': conversions },
        'date' => { 'N': (dt.year - 2000) * 1000 + dt.yday },
        'sid' => { 'N': site_element.id }
      }
    end

    initialize_with do
      OpenStruct.new(
        views: views,
        conversions: conversions,
        date: date,
        site_element: site_element
      )
    end
  end
end
