class FetchSiteStatisticsFromES
  def initialize(site)
    @site = site
  end

  def call
    fetch
  end

  private

  attr_reader :site

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
      terms: { sid: site_element_ids }
    )
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
