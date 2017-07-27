class ChartDataSerializer
  attr_reader :site_element_statistics, :type, :sample_size

  def initialize(site_element_statistics, type, sample_size: nil)
    @site_element_statistics = site_element_statistics
    @type = type
    @sample_size = sample_size
  end

  def as_json
    days_range.map do |date|
      {
        date: date.strftime('%-m/%d'),
        value: site_element_statistics.send(method, date)
      }
    end
  end

  private

  def from_date
    # compensate "today" by "+ 1"
    Date.current - (sample_size.present? ? [site_element_statistics.size, sample_size.to_i].min : site_element_statistics.size) + 1
  end

  def days_range
    from_date..Date.current
  end

  def method
    type == 'total' ? :views : :conversions
  end
end
