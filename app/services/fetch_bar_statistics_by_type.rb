class FetchBarStatisticsByType
  def initialize(site, days_limit:)
    @site = site
    @days_limit = days_limit
    @totals = {}
  end

  def call
    totals[:total] = statistics.totals
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
    statistics.for_goal(goal)
  end
end
