class BarStatistics
  include Enumerable

  Record = Struct.new(:views, :conversions, :date, :site_element_id)
  Total = Struct.new(:views, :conversions)

  delegate :each, :[], to: :@records

  def initialize(records = [])
    @records = records
  end

  def <<(item)
    @records << Record.new(item['v'].to_i, item['c'].to_i, item['date'], item['sid'].to_i)
  end

  def views(date = Date.current)
    select { |record| record.date <= date.to_date }.sum(&:views)
  end

  def conversions(date = Date.current)
    select { |record| record.date <= date.to_date }.sum(&:conversions)
  end

  def views_between(a, b = Date.current)
    select { |record| record.date.in? a.to_date..b.to_date }.sum(&:views)
  end

  def conversions_between(a, b = Date.current)
    select { |record| record.date.in? a.to_date..b.to_date }.sum(&:conversions)
  end

  def conversion_percent_between(a, b = Date.current)
    views = views_between(a, b)
    return 0 if views.zero?
    conversions_between(a, b) / views.to_f
  end

  class Totals < OpenStruct
    # @param [Symbol] key
    # @param [Array<BarStatistics>] statistics
    def set(key, statistics)
      self[key] = Total.new(statistics.sum(&:views), statistics.sum(&:conversions))
      self
    end
  end
end
