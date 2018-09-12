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
      growth: growth,
      pro: pro,
      elite: elite,
      growth_monthly: growth_monthly,
      growth_yearly: growth_yearly,
      pro_monthly: pro_monthly,
      pro_yearly: pro_yearly,
      elite_monthly: elite_monthly,
      elite_yearly: elite_yearly
    )
  end

  def beginning_of_current_week
    # metrics for USA, to match QuickSight data, so week starts on a Sunday
    @beginning_of_current_week ||= Date.current.beginning_of_week(:sunday)
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

  def growth
    @growth ||= revenue.select { |bill| bill.subscription&.type =~ /Growth/ }
  end

  def elite
    @elite ||= revenue.select { |bill| bill.subscription&.type =~ /Elite/ }
  end

  def pro_monthly
    @pro_monthly ||= pro.select { |bill| bill.subscription&.monthly? }
  end

  def pro_yearly
    @pro_yearly ||= pro.select { |bill| bill.subscription&.yearly? }
  end

  def growth_monthly
    @growth_monthly ||= growth.select { |bill| bill.subscription&.monthly? }
  end

  def growth_yearly
    @growth_yearly ||= growth.select { |bill| bill.subscription&.yearly? }
  end

  def elite_monthly
    @elite_monthly ||= elite.select { |bill| bill.subscription&.monthly? }
  end

  def elite_yearly
    @elite_yearly ||= elite.select { |bill| bill.subscription&.yearly? }
  end
end
