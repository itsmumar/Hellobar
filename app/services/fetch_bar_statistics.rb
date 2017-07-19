class FetchBarStatistics
  CACHE_TTL = 1.hour

  def initialize(site, days_limit:)
    @site = site
    @days_limit = days_limit
  end

  def call
    statistics.clear # clear the results in case we are calling this service object a second time
    process DynamoDB.new(cache_key: cache_key, expires_in: CACHE_TTL).scan(request)
  end

  private

  attr_reader :site, :days_limit

  def process(response)
    response.each do |item|
      item['date'] = convert_from_weird_date item['date'].to_i
      statistics[item['sid'].to_i] << item
    end
    statistics
  end

  def statistics
    @statistics ||= Hash.new { |hash, k| hash[k] = BarStatistics.new }
  end

  def cache_key
    "#{ site.cache_key }/#{ days_limit }"
  end

  def request
    ids_query = site_element_ids.map { |id| [":sid#{ id }", id] }.to_h
    {
      table_name: table,
      filter_expression: "#D >= :last_date AND sid IN (#{ ids_query.keys.join(',') })",
      expression_attribute_names: { '#D' => 'date' },
      expression_attribute_values: { ':last_date' => last_date }.merge(ids_query),
      select: 'ALL_ATTRIBUTES',
      return_consumed_capacity: 'INDEXES',
      limit: days_limit * site_element_ids.size
    }
  end

  def site_element_ids
    @site_element_ids ||= site.site_elements.ids
  end

  def table
    'over_time'
  end

  def last_date
    convert_to_weird_date days_limit.days.ago
  end

  # convert 2017-01-01 to "17001"
  # this comes from DynamoDB
  # where such weird thing is used as a key
  # see "over_time" table
  #
  # first 2 numbers represent year
  #   i.e. 17 for 2017, 10 for 2010
  # last 3 numbers represent day of year
  #   i.e. 001 for 1 Jun, 365 for 31 Dec, 188 for 29 Mar
  def convert_to_weird_date(date)
    (date.year - 2000) * 1000 + date.yday
  end

  # convert "17001" to 2017-01-01
  def convert_from_weird_date(date)
    year = date.to_s[0..1].to_i + 2000
    yday = date.to_s[2..4].to_i
    yday.days.since(Date.new(year) - 1)
  end
end
