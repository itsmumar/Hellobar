class CalculateInternalMetrics
  def call
    calculate_internal_metrics
  end

  private

  def calculate_internal_metrics
    OpenStruct.new(
      beginning_of_current_week: beginning_of_current_week,
      beginning_of_last_week: beginning_of_last_week,
      users: users,
      sites: sites,
      still_installed_sites: still_installed_sites,
      revenue: revenue,
      revenue_sum: revenue_sum,
      pro: pro,
      enterprise: enterprise,
      pro_monthly: pro_monthly,
      pro_yearly: pro_yearly,
      enterprise_monthly: enterprise_monthly,
      enterprise_yearly: enterprise_yearly
    )
  end

  def beginning_of_current_week
    @beginning_of_current_week ||= Date.commercial(Date.current.year, Date.current.cweek, 1)
  end

  def beginning_of_last_week
    @beginning_of_last_week ||= beginning_of_current_week - 1.week
  end

  def users
    @users ||= User.where('created_at >= ? and created_at < ?', beginning_of_last_week, beginning_of_current_week)
  end

  def sites
    @sites ||= Site.where('created_at >= ? and created_at < ?', beginning_of_last_week, beginning_of_current_week)
  end

  def still_installed_sites
    @still_installed_sites ||= sites.select(&:script_installed?)
  end

  def revenue
    @revenue ||=
      Bill.paid.where('created_at >= ? AND created_at < ?',
        beginning_of_last_week, beginning_of_current_week)
  end

  def revenue_sum
    @revenue_sum ||= revenue.sum(:amount)
  end

  def pro
    @pro ||= revenue.select { |bill| bill.subscription&.type =~ /Pro/ }
  end

  def enterprise
    @enterprise ||= revenue.select { |bill| bill.subscription&.type =~ /Enterprise/ }
  end

  def pro_monthly
    @pro_monthly ||= pro.select { |bill| bill.subscription&.monthly? }
  end

  def pro_yearly
    @pro_yearly ||= pro.select { |bill| bill.subscription&.yearly? }
  end

  def enterprise_monthly
    @enterprise_monthly ||= enterprise.select { |bill| bill.subscription&.monthly? }
  end

  def enterprise_yearly
    @enterprise_yearly ||= enterprise.select { |bill| bill.subscription&.yearly? }
  end
end
