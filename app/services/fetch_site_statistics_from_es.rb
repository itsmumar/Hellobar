class FetchSiteStatisticsFromES
  def initialize(site, start_date, end_date)
    @site = site
    @start_date = start_date
    @end_date = end_date
  end

  def call
    fetch
  end

  private

  attr_reader :site, :start_date, :end_date

  def fetch
    query.aggs(aggrigations).aggs
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
                gte: WeirdDate.from_date(@start_date),
                lte: WeirdDate.from_date(@end_date)
            }
        }
    ).filter(terms: { sid: site_element_ids })
  end

  def site_element_ids
    [114354]
  end
end