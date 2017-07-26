class BarStatistics
  include Enumerable

  Record = Struct.new(:views, :conversions, :date, :site_element_id) do
    def +(other)
      raise 'Cannot sum records with different dates' unless other.date == date
      self.class.new(views + other.views, conversions + other.conversions, date, nil)
    end
  end

  delegate :each, :clear, :empty?, :size, :[], to: :@records

  attr_reader :records

  def initialize(records = [])
    @records = records
  end

  def <<(item)
    @records << Record.new(item['v'].to_i, item['c'].to_i, item['date'], item['sid'].to_i)
  end

  def +(other)
    merged_records = (records + other.records).group_by(&:date).values.map { |same_day_records| same_day_records.inject :+ }
    BarStatistics.new(merged_records)
  end

  def has_views?
    views > 0
  end

  def views(date = Date.current)
    select { |record| record.date <= date.to_date }.sum(&:views).to_f
  end

  def conversions(date = Date.current)
    select { |record| record.date <= date.to_date }.sum(&:conversions).to_f
  end

  def views_between(a, b = Date.current)
    select { |record| record.date.in? a.to_date..b.to_date }.sum(&:views).to_f
  end

  def conversions_between(a, b = Date.current)
    select { |record| record.date.in? a.to_date..b.to_date }.sum(&:conversions).to_f
  end

  def conversion_rate(date = Date.current)
    views = views(date)
    views == 0 ? 0 : conversions(date).to_f / views
  end

  def conversion_rate_between(a, b = Date.current)
    views = views_between(a, b)
    views == 0 ? 0 : conversions_between(a, b).to_f / views
  end

  def conversion_percent_between(a, b = Date.current)
    conversion_rate_between(a, b) * 100
  end
end
