class FetchSiteStatistics
  # 5 years; basically we don't care of it
  # but since we must filter by date
  # let's take some synthetic date
  MAX_DAYS = 5 * 365

  CACHE_TTL = 1.hour

  def initialize(site, days_limit: MAX_DAYS)
    @site = site
    @days_limit = days_limit
    @site_elements ||= site.site_elements
  end

  def call
    cache { fetch_statistic }
  end

  private

  attr_reader :site, :days_limit, :site_elements

  def fetch_statistic
    statistics = SiteStatistics.new
    site_elements.each do |site_element|
      dynamo_db_for(site_element).query_each(request_for(site_element.id)) do |item|
        statistics << enhance_record(site_element, item)
      end
    end
    statistics
  end

  def request_for(id)
    {
      table_name: table_name,
      key_condition_expression: '#D >= :last_date AND sid = :sid',
      expression_attribute_names: { '#D' => 'date' },
      expression_attribute_values: { ':last_date' => last_date, ':sid' => id },
      projection_expression: '#D, c, v, sid',
      return_consumed_capacity: 'TOTAL',
      limit: days_limit
    }
  end

  def table_name
    DynamoDB.visits_table_name
  end

  def last_date
    convert_to_weird_date days_limit.days.ago
  end

  def enhance_record(site_element, item)
    attributes = {
      'date' => convert_from_weird_date(item['date'].to_i),
      'goal' => site_element.short_subtype
    }
    item.merge(attributes)
  end

  def convert_to_weird_date(date)
    WeirdDate.from_date date
  end

  # convert "17001" to 2017-01-01
  def convert_from_weird_date(date)
    WeirdDate.to_date date
  end

  def dynamo_db_for(site_element)
    DynamoDB.new(cache_context: site_element.cache_key)
  end

  def cache
    Rails.cache.fetch(all_site_statistics_cache_key, expires_in: CACHE_TTL) { yield }
  end

  def all_site_statistics_cache_key
    key = [site, site.site_elements.reorder(:updated_at).last]
    ActiveSupport::Cache.expand_cache_key key, "site_statistics/#{ days_limit }"
  end
end
