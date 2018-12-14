class FetchGraphStatisticsFromES
  def initialize(site, start_date, end_date, type)
    @site = site
    @start_date = start_date.is_a?(String) ? Date.parse(start_date) : start_date
    @end_date = end_date.is_a?(String) ? Date.parse(end_date) : end_date
    @type = type
  end

  def call
    fetch
  end

  private

  attr_reader :site, :start_date, :end_date, :type

  def fetch
    raw_result = query.aggs(aggrigations).aggs['by_date']['buckets'].sort_by { |row| row['key'] }

    field = (type.nil? || type == 'total') ? 'v' : 'c'
    raw_result.map do |rec|
      {
        date: WeirdDate.to_date(rec['key']).strftime('%-m/%d'),
        value: rec["#{field}"]['value']
      }
    end
  end

  def aggrigations
    {
      by_date: {
        terms: { field: 'date' },
        aggs: {
          v: { sum: { field: 'v' } }
        }
      }
    }
  end

  def query
    OverTimeIndex.filter(
      range: {
        date: {
          gte: WeirdDate.from_date(start_date),
          lte: WeirdDate.from_date(end_date)
        }
      }
    ).filter(terms: { sid: site_element_ids })
  end

  def site_element_ids
    if type.nil? || type == 'total'
      site.site_elements.ids
    else
      site.site_elements.where(element_subtype: type).ids
    end
  end
end
