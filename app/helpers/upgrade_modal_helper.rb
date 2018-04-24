module UpgradeModalHelper
  # returns a button based on the subscription
  def choose_plan_button(subscription, copy = 'Choose Plan')
    content_tag :div, class: 'button', 'data-package' => SubscriptionSerializer.new(subscription, scope: current_user).to_json do
      copy
    end
  end

  def choose_pro_or_growth_button(copy = 'Choose Plan')
    choose_plan_button Subscription.pro_or_growth_for(current_user).new, copy
  end
end
