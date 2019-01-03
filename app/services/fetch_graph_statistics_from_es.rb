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
    raw_result = query.aggs(aggrigations).aggs['by_date']['buckets']

    response = raw_result.map do |rec|
      {
        date: WeirdDate.to_date(rec['key']).strftime('%-m/%d'),
        key: rec['key'],
        value: rec['total_views']['value']
      }
    end

    (start_date...end_date).to_a.each do |date|
      next if response.map(&:values).map(&:first).include? date.strftime('%-m/%d')
      response << { date: date.strftime('%-m/%d'),
          key: WeirdDate.from_date(date),
          value: 0 }
    end

    response.sort_by { |row| row[:key] }
  end

  def aggrigations
    {
      by_date: {
        terms: { field: 'date', size: number_of_days },
        aggs: {
          total_views: { sum: { field: type.nil? || type == 'total' ? 'v' : 'c' } }
        }
      }
    }
  end

  def number_of_days
    (end_date - start_date).to_i + 1
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
