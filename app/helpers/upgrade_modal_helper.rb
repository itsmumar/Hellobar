module UpgradeModalHelper
  # returns a button based on the subscription
  def choose_plan_button(subscription)
    content_tag :div, class: 'button', 'data-package' => SubscriptionSerializer.new(subscription, scope: current_user).to_json do
      'Choose Plan'
    end
  end
end
