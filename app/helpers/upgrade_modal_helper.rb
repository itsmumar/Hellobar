module UpgradeModalHelper
  # returns a button based on the subscription
  def choose_plan_button(subscription, plan)
    subscription_type = subscription.type.split('::').last.downcase

    if subscription_type == plan
      content_tag :div, class: 'button', disabled: 'disabled' do
        'Current Plan'
      end
    else
      content_tag :div, class: 'button', 'data-package' => subscription_type do
        'Choose Plan'
      end
    end
  end
end
