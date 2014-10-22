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

  # sets a flash when there are errors with their payment method
  def render_payment_errors
    if @site.present? && @site.bills_with_payment_issues.present?
      total_bill_amount = @site.bills_with_payment_issues.inject(0){|sum,b| sum+=b.amount}
      first_bill_date = @site.bills_with_payment_issues.sort{|a,b| a.bill_at <=> b.bill_at}.first.bill_at

      flash.now[:error] = "You have outstanding bills in the amount of #{number_to_currency(total_bill_amount)} since #{first_bill_date.strftime("%-m-%-d-%Y")}"
    end
  end
end
