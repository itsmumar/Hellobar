class UserUpgradePolicy
  MAX_VIEW_IN_MONTH = 1000

  def initialize(resource, has_paying_subscription)
    @user = resource
    @has_paying_subscription = has_paying_subscription
  end

  def should_show_upgrade_suggest_modal?
    # Freemium user that have HB installed and active.
    return false if @has_paying_subscription || no_script_installed?
    return false unless any_max_total_views_in_month?

    already_viewed_before? @user.upgrade_suggest_modal_last_shown_at
  end

  def should_show_exit_intent_modal?
    return false if @has_paying_subscription
    already_viewed_before? @user.exit_intent_modal_last_shown_at
  end

  private

  def no_script_installed?
    @user.sites.select(&:script_installed?).empty?
  end

  # At least one active HB bar for that user should have received
  # 1000 views in the last 30 days
  def any_max_total_views_in_month?
    @user.site_elements.active.any? do |site_element|
      statistics = FetchSiteStatistics.new(site_element.site, days_limit: 30).call
      statistics[site_element.id].views >= MAX_VIEW_IN_MONTH
    end
  end

  def already_viewed_before?(last_shown_at)
    last_shown_at.present? ? last_shown_at < max_recurring_time : true
  end

  # only show once every 30 days
  def max_recurring_time
    30.days.ago
  end
end
