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
end
