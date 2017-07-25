FactoryGirl.define do
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
