class FetchBarStatistics
  def initialize(site, days_limit:)
    @site = site
    @days_limit = days_limit
  end

  def call
    statistics.clear # clear the results in case we are calling this service object a second time
    site_elements.each { |site_element| process site_element }
    statistics
  end

  private

  attr_reader :site, :days_limit

  def process(site_element)
    request = request_for(site_element.id)
    process_response site_element.id, dynamo_db_for(site_element).fetch(request)
  end

  def process_response(site_element_id, response)
    response.each do |item|
      item['date'] = convert_from_weird_date item['date'].to_i
      statistics[site_element_id] << item
    end
  end

  def statistics
    @statistics ||= Hash.new { |hash, k| hash[k] = BarStatistics.new }
  end

  def request_for(id)
    {
      table_name: table,
      key_condition_expression: "#D >= :last_date AND sid = :sid",
      expression_attribute_names: { '#D' => 'date' },
      expression_attribute_values: { ':last_date' => last_date, ':sid' => id },
      projection_expression: '#D, c, v, sid',
      return_consumed_capacity: 'INDEXES',
      limit: days_limit
    }
  end

  def site_elements
    @site_elements ||= site.site_elements
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

  def dynamo_db_for(site_element)
    DynamoDB.new(cache_key: "#{ site_element.cache_key }/#{ days_limit }")
  end
end
