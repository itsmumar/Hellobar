module UpgradeModalHelper
  # returns a button based on the subscription
  def choose_plan_button(subscription, plan)
    subscription ||= Subscription::Free.new
    subscription_type = subscription.type.split('::').last.downcase

    if subscription_type == plan
      content_tag :div, class: 'button', disabled: 'disabled' do
        'Current Plan'
      end
    else
      content_tag :div, class: 'button', 'data-package' => plan do
        'Choose Plan'
      end
    end
  end
end
