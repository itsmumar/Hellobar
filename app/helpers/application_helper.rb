require "avatar/view/action_view_support"

module ApplicationHelper
  include Avatar::View::ActionViewSupport

  def page_id
    if controller_name == 'pages' && params[:page]
      [controller_name, params[:page]].join('-')
    else
      [controller_name, action_name].join('-')
    end
  end

  def show_account_prompt?
    current_user && current_user.temporary? &&
      !(params[:controller] == "user" && params[:action] == "edit") &&
      !(params[:controller] == "user" && params[:action] == "update")
  end

  def subscription_cost(subscription, schedule)
    cost = subscription.estimated_price(current_user, schedule)
    cost = cost / 12 if schedule == :yearly
    number_to_currency(cost, precision: 0)
  end

  def hellobar_script_tag
    render 'shared/hellobar_script'
  end
end
