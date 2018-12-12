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
    {
        total: {
            filter: {
                terms: { sid: site_element_ids }
            },
            aggs: {
                v: { sum: { field: "v" } }
            }
        },
        call: {
            filter: {
                terms: { sid: site_element_ids('call') }
            },
            aggs: {
                c: { sum: { field: "c" } }
            }
        },
        email: {
            filter: {
                terms: { sid: site_element_ids('email') }
            },
            aggs: {
                c: { sum: { field: "c" } }
            }
        },
        traffic: {
            filter: {
                terms: { sid: site_element_ids('traffic') }
            },
            aggs: {
                c: { sum: { field: "c" } }
            }
        },
        social: {
            filter: {
                terms: { sid: site_element_ids('social') }
            },
            aggs: {
                c: { sum: { field: "c" } }
            }
        }
    }
  end

  def query
    OverTimeIndex.filter(
        { terms: { sid: site_element_ids } }
    )
  end

  def normalize result
    normalized = {}
    result.each do |k, v|
      if v["c"]
        normalized[k.to_sym] = v["c"]["value"]
      else
        normalized[k.to_sym] = v["v"]["value"]
      end
    end

    normalized
  end

  def site_element_ids subtype = nil
    return site.site_elements.ids unless subtype

    site.site_elements.where(element_subtype: subtype).ids
  end
end