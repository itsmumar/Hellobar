class FetchBarsStatisticsByType
  def initialize(site, days_limit:)
    @site = site
    @days_limit = days_limit
  end

  def call
    statistics = FetchBarsStatistics.new(site, days_limit: days_limit).call
    totals = BarStatistics::Totals.new.set :total, statistics.values

    %i[call email social traffic].each do |type|
      totals.set type, statistics_for_type(statistics, type)
    end
  end

  private

  attr_reader :site, :days_limit

  def statistics_for_type(statistics, type)
    statistics.select { |site_element_id| element_type[site_element_id] == type }.values
  end

  def element_type
    @element_type ||= site.site_elements.map { |element|
      [element.id, element.short_subtype.to_sym]
    }.to_h
  end
end
