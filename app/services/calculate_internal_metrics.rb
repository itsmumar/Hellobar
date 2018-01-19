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
      installed_sites: installed_sites,
      still_installed_sites: still_installed_sites,
      installation_churn: installation_churn,
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
    # metrics for USA, to match QuickSight data, so week starts on a Sunday
    Date.beginning_of_week = :sunday

    Date.current.beginning_of_week.tap do
      # Revert back to Monday
      Date.beginning_of_week = :monday
    end
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

  def installed_sites
    @installed_sites ||= sites.select { |site| site.script_installed_at.present? }
  end

  def still_installed_sites
    @still_installed_sites ||= sites.select(&:script_installed?)
  end

  def installation_churn
    installed_size = installed_sites.size
    still_installed_size = still_installed_sites.size

    @installation_churn ||=
      (installed_size - still_installed_size) / installed_size.to_f
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
