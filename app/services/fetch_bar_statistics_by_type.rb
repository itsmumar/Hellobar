class FetchBarStatisticsByType
  def initialize(site, days_limit:)
    @site = site
    @days_limit = days_limit
    @totals = {}
  end

  def call
    totals[:total] = merge_statistics(statistics)
    set_statistics_for_goals
    totals
  end

  private

  attr_reader :site, :days_limit, :totals

  def statistics
    @statistics ||= FetchBarStatistics.new(site, days_limit: days_limit).call
  end

  def set_statistics_for_goals
    %i[call email social traffic].each do |goal|
      totals[goal] = statistics_for_goal(statistics, goal)
    end
  end

  def statistics_for_goal(statistics, goal)
    merge_statistics statistics.select { |site_element_id| element_goal[site_element_id] == goal }
  end

  def merge_statistics(statistics)
    statistics.values.inject(:+) || BarStatistics.new
  end

  def element_goal
    @element_goal ||= site.site_elements.map { |element|
      [element.id, element.short_subtype.to_sym]
    }.to_h
  end
end
