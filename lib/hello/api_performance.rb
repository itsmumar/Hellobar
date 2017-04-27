require Rails.root.join('config', 'initializers', 'settings.rb')
require './lib/hello/data_api_helper'

module Hello::DataAPI
  class Performance
    attr_accessor :data

    def initialize(data)
      @data = data
    end

    def views(date = Date.today)
      data_for(date, 0)
    end

    def conversions(date = Date.today)
      data_for(date, 1)
    end

    def views_between(d1, d2 = Date.today)
      data_for(d2, 0) - data_for(d1, 0)
    end

    def conversions_between(d1, d2 = Date.today)
      data_for(d2, 1) - data_for(d1, 1)
    end

    def conversion_percent_between(d1, d2 = Date.today)
      v = views_between(d1, d2)
      return 0 if v == 0
      conversions_between(d1, d2) / v.to_f
    end

    # Gets change in conversions between two sets of dates
    # conversion_change_between(2.week.ago, 1.week.ago, 1.week.ago, Time.now)
    def conversion_change_between(d1, d2, d3, d4)
      n = conversions_between(d3, d4)
      d = conversions_between(d1, d2)
      d == 0 ? nil : ((n / d.to_f) - 1) * 100
    end

    def respond_to?(sym, include_private = false)
      super(sym, include_private) || data.respond_to?(sym, include_private)
    end

    def method_missing(method, *args, &block)
      return data.send(method, *args, &block) if data.respond_to?(method)
      super
    end

    def respond_to_missing?(method, *)
      data.respond_to?(method) || super
    end

    private

    def date_to_index(date)
      index = data.length - 1 - (Date.today - date).to_i
      return nil if index < 0
      return data.length - 1 if index >= data.length
      index
    end

    def data_for(date, type)
      date = date.to_date
      return 0 if data.empty?
      index = date_to_index(date)
      return 0 unless index
      data[index][type]
    end
  end
end
