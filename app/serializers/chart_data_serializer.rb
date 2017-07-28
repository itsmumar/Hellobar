class ChartDataSerializer
  attr_reader :site_statistics, :type, :days_limit

  def initialize(site_statistics, params)
    @type = params[:type].to_sym
    @days_limit = params[:days].presence&.to_i
    @site_statistics = site_statistics
  end

  def as_json
    date_range.map do |date|
      {
        date: date.strftime('%-m/%d'),
        value: statistics_for_type.until(date).send(method)
      }
    end
  end

  private

  def date_range
    first_date..Date.current
  end

  def statistics_for_type
    @statistics_for_type ||= site_statistics.for_goal(type)
  end

  def first_date
    return site_statistics.days.last unless limit_data?
    # compensate today so that
    # `days_number = 2` means get 2 days -- yesterday and today
    (days_limit - 1).days.ago.to_date
  end

  def limit_data?
    days_limit.present? && days_limit < site_statistics.days.size
  end

  def method
    type == :total ? :views : :conversions
  end
end
