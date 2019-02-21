class FetchTotalViewsForMonth
  def initialize(sites)
    @sites = sites
  end

  def call
    fetch
  end

  private

  attr_reader :sites

  def fetch
    response = query.aggs(aggregations)
    response.aggregations.inject({}) do |hash, (site_id, agg)|
      hash.update site_id.to_i => agg.dig('total_views', 'value').to_i
    end
  end

  def aggregations
    sites.inject({}) do |hash, site|
      hash.update site.id.to_s => {
        filter: { terms: { sid: site.site_elements.ids } },
        aggs: {
          total_views: { sum: { field: 'v' } }
        }
      }
    end
  end

  def query
    OverTimeIndex.filter(
      range: {
        date: {
          gte: WeirdDate.from_date(Date.current.beginning_of_month),
          lte: WeirdDate.from_date(Date.current.end_of_month)
        }
      }
    )
  end
end
