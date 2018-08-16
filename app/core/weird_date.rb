class WeirdDate
  # convert 2017-01-01 to "17001"
  # this comes from DynamoDB
  # where such weird thing is used as a key
  # see "over_time" table
  #
  # first 2 numbers represent year
  #   i.e. 17 for 2017, 10 for 2010
  # last 3 numbers represent day of year
  #   i.e. 001 for 1 Jun, 365 for 31 Dec, 088 for 29 Mar
  def self.from_date(date)
    (date.year - 2000) * 1000 + date.yday
  end

  # convert "17001" to 2017-01-01
  def self.to_date(date)
    year = date.to_s[0..1].to_i + 2000
    yday = date.to_s[2..4].to_i
    yday.days.since(Date.new(year) - 1)
  end
end
