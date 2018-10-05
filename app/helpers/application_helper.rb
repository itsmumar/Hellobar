require 'avatar/view/action_view_support'

module ApplicationHelper
  include Avatar::View::ActionViewSupport

  def yes_or_no(value)
    if value
      'Yes'
    else
      'No'
    end
  end

  def page_id
    if controller_name == 'pages' && params[:page]
      [controller_name, params[:page]].join('-')
    else
      [controller_name, action_name].join('-')
    end
  end

  def show_account_prompt?
    current_user&.temporary? &&
      !(params[:controller] == 'user' && params[:action] == 'edit') &&
      !(params[:controller] == 'user' && params[:action] == 'update')
  end

  def subscription_cost_by_plan name, interval
    subscription_cost("Subscription::#{name.titlize}", interval.to_sym)
  end

  def subscription_cost(subscription, schedule)
    cost = subscription.estimated_price(current_user, schedule)
    number_to_currency(cost, precision: 0)
  end

  def time_zone_options
    filtered_timezone_list.map { |tz| [tz.to_s, tz.tzinfo.identifier] }
  end

  def filtered_timezone_list
    ActiveSupport::TimeZone.all.uniq(&:tzinfo)
  end

  def serialize_current_user
    UserSerializer.new(current_user).to_json
  end

  def serialize_current_site
    current_site ? SiteSerializer.new(current_site, scope: { user: current_user }).to_json : {}
  end

  def pro_or_growth(user = nil)
    user ||= current_user
    @pro_or_growth ||= Subscription.pro_or_growth_for(user).defaults[:name]
  end

  def pro_or_growth_price(user = nil)
    user ||= current_user
    @pro_or_growth_price ||=
      number_to_currency(
        Subscription.pro_or_growth_for(user).defaults[:monthly_amount],
        precision: 0
      )
  end

  def format_date(datetime, format = '%F')
    datetime&.strftime(format)
  end
end
