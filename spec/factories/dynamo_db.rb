FactoryBot.define do
  factory :site_statistics, class: SiteStatistics do
    skip_create

    transient do
      first_date { Date.current }
      site_element_id nil
      goal :foo
      views []
      conversions []
    end

    initialize_with do
      records =
        views.zip(conversions).map.with_index do |(view, conversion), number|
          attributes = {
            views: view || 0,
            conversions: conversion || 0,
            date: number.days.until(first_date).to_date,
            site_element_id: site_element_id,
            goal: goal
          }
          create :site_statistics_record, attributes
        end
      SiteStatistics.new records.reverse
    end

    trait :with_views do
      transient do
        views [1, 2, 3, 4]
      end
    end
  end

  factory :site_statistics_record, class: SiteStatistics::Record do
    skip_create

    site_element_id nil
    goal :email
    views { 100 }
    conversions { 10 }
    date { Date.current }

    initialize_with do
      SiteStatistics::Record.new(
        views,
        conversions,
        date,
        site_element_id,
        goal
      )
    end
  end
end
