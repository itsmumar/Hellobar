class UserUpgradePolicy

  MAX_RECURRING_TIME = 30.days.ago # only show once every 30 days
  MAX_VIEW_IN_MONTH = 1000

  def initialize(resource, has_paying_subscription)
    @user = resource
    @has_paying_subscription = has_paying_subscription
  end

  # [2016.05] Upgrade Pop-up for Active Users
  # Freemium users that have HB installed - done
  # At least one HB bar for that user should have received 1000 views in the last 30 days
  # In the testing variant

  def should_show_upgrade_suggest_modal?
    return false if @has_paying_subscription
    return false if !any_max_total_views_in_month?

    already_viewed_before? @user.upgrade_suggest_modal_last_shown_at

    # @user.upgrade_suggest_modal_last_shown_at.present? ? @user.upgrade_suggest_modal_last_shown_at < MAX_RECURRING_TIME : true
  end

  def should_show_exit_intent_modal?
    debugger
    return false if @has_paying_subscription
    already_viewed_before? @user.exit_intent_modal_last_shown_at

    # @user.exit_intent_modal_last_shown_at.present? ? @user.exit_intent_modal_last_shown_at < MAX_RECURRING_TIME : true
  end

  private

  def any_max_total_views_in_month?
    true
    # At least one HB bar for that user should have received 1000 views in the last 30 days

  end

  def already_viewed_before?(last_shown_at)
    last_shown_at.present? ? last_shown_at < MAX_RECURRING_TIME : true
  end

end
