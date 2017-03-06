module UpgradeModalHelper
  # returns a button based on the subscription
  def choose_plan_button(subscription, copy = 'Choose Plan')
    content_tag :div, class: 'button', 'data-package' => SubscriptionSerializer.new(subscription, scope: current_user).to_json do
      copy
    end
  end
end
