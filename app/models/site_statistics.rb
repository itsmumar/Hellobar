class SiteStatistics
  include Enumerable

  Record = Struct.new(:views, :conversions, :date, :site_element_id, :goal)

  delegate :select, :empty?, :size, :each, :clear, to: :@records

  attr_reader :records

  def initialize(records = [])
    @records = records
  end

  def <<(item)
    @records << Record.new(
      item['v'].to_i,
      item['c'].to_i,
      item['date'],
      item['sid'].to_i,
      item['goal'].to_sym
    )
  end

  def site_element_ids
    map(&:site_element_id)
  end

  def days
    group_by(&:date).keys
  end

  def with_views
    scope { |record| !record.views.zero? }
  end

  def for_element(id)
    scope { |record| record.site_element_id == id }
  end

  def for_goal(goal)
    scope { |record| record.goal == goal }
  end

  def between(a, b = Date.current)
    scope { |record| record.date.in? a.to_date..b.to_date }
  end

  def until(date)
    scope { |record| record.date <= date.to_date }
  end

  def views?
    views > 0
  end

  def views
    records.sum(&:views)
  end

  def conversions
    records.sum(&:conversions)
  end

  def conversion_rate
    views == 0 ? 0 : conversions.to_f / views
  end

  def conversion_percent
    conversion_rate * 100
  end

  private

  def scope(&block)
    SiteStatistics.new(select(&block))
  end
end
