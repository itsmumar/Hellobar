class SiteStatistics
  delegate :[], :fetch, :empty?, :clear, to: :@site_element_statistics

  attr_reader :site_element_statistics

  def initialize(site_element_statistics = nil, site_elements: [])
    @site_elements = site_elements
    @site_element_statistics = site_element_statistics || Hash.new { |hash, k| hash[k] = BarStatistics.new }
  end

  def totals
    @totals ||= site_element_statistics.values.inject(:+) || BarStatistics.new
  end

  def for_goal(goal)
    elements_with_goal = @site_elements.select { |element| element.short_subtype.to_sym == goal }.map(&:id)
    statistics_for_goal =
      site_element_statistics.select { |site_element_id| site_element_id.in? elements_with_goal }.values
    merge_records(statistics_for_goal)
  end

  def views?
    views > 0
  end

  def views
    site_element_statistics.values.sum(&:views).to_f
  end

  def conversions
    site_element_statistics.values.sum(&:conversions).to_f
  end

  private

  def merge_records(site_element_statistics)
    site_element_statistics.inject(:+) || BarStatistics.new
  end
end
