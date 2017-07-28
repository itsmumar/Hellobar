class ChartDataSerializer
  attr_reader :site_statistics, :type, :sample_size

  def initialize(site_statistics, params)
    @site_statistics = site_statistics
    @type = params[:type].to_sym
    @sample_size = params[:days].to_i
  end

  def as_json
    days_range.map do |date|
      {
        date: date.strftime('%-m/%d'),
        value: statistics_for_type.until(date).send(method)
      }
    end
  end

  private

  def statistics_for_type
    if type == :total
      site_statistics
    else
      site_statistics.for_goal(type)
    end
  end

  def from_date
    # compensate today so that
    # `days_number = 2` means get 2 days -- yesterday and today
    (days_number - 1).days.ago.to_date
  end

  def days_number
    if sample_size.present?
      [site_statistics.days.size, sample_size.to_i].min
    else
      site_statistics.days.size
    end
  end

  def days_range
    from_date..Date.current
  end

  def method
    type == :total ? :views : :conversions
  end
end
