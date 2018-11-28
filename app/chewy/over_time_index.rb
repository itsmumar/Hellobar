class OverTimeIndex < Chewy::Index
  define_type :over_time_type do
    field :date, type: 'integer'
    field :c, type: 'integer'
    field :v, type: 'integer'
    field :sid, type: 'integer'

    def self.type_name
      "#{ Rails.env }_over_time_type"
    end

    def conversions
      c
    end

    def views
      v
    end

    # convert "17001" to 2017-01-01
    def date
      date = attributes['date']
      year = date.to_s[0..1].to_i + 2000
      yday = date.to_s[2..4].to_i
      yday.days.since(Date.new(year) - 1)
    end

    def site_element_id
      sid
    end

    def site_element
      SiteElement.find(site_element_id)
    end
  end
end
