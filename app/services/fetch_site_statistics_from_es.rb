class FetchSiteStatisticsFromES
  def initialize(site, start_date, end_date)
    @site = site
    @start_date = start_date.is_a?(String) ? Date.parse(start_date) : start_date
    @start_date ||= Time.zone.today - 29.days
    @end_date = end_date.is_a?(String) ? Date.parse(end_date) : end_date
    @end_date ||= Time.zone.today
  end

  def call
    fetch
  end

  private

  attr_reader :site, :start_date, :end_date

  def fetch
    normalize(query.aggs(aggrigations).aggs)
  end

  def aggrigations
    agg = {
      total: {
        filter: {
          terms: { sid: site_element_ids }
        },
        aggs: {
          v: { sum: { field: 'v' } }
        }
      }
    }

    %i[call email traffic social].each do |type|
      agg[type] = {
        filter: {
          terms: { sid: site_element_ids(type.to_s) }
        },
        aggs: {
          c: { sum: { field: 'c' } }
        }
      }
    end

    agg
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

  def normalize result
    normalized = {}
    result.each do |k, v|
      value = v['c'] ? v['c']['value'] : v['v']['value']
      normalized[k.to_sym] = value
    end

    normalized
  end

  def site_element_ids subtype = nil
    return site.site_elements.ids unless subtype

    site.site_elements.where('element_subtype like?', "#{ subtype }%").ids
  end
end
