module UpgradeModalHelper
  # returns a button based on the subscription
  def choose_plan_button(subscription, copy=nil)
    content_tag :div, class: 'button', 'data-package' => SubscriptionSerializer.new(subscription, scope: current_user).to_json do
      copy.present? ? copy : 'Choose Plan'
    end
  end
end
