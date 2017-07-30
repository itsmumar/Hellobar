class FetchSiteStatistics
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
    process_response site_element, dynamo_db_for(site_element).fetch(request)
  end

  def process_response(site_element, response)
    response.each do |item|
      statistics << enhance_record(site_element, item)
    end
  end

  def statistics
    @statistics ||= SiteStatistics.new
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

  def site_elements
    @site_elements ||= site.site_elements
  end

  def table_name
    case Rails.env
    when 'staging'
      'staging_over_time'
    when 'production'
      'over_time'
    else # edge / development / test
      'edge_over_time2'
    end
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
