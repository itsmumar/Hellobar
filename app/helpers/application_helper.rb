require "avatar/view/action_view_support"

module ApplicationHelper
  include Avatar::View::ActionViewSupport

  def sidebar_link_class(link)
    active = case link
      when :summary
        params[:controller] == "sites" && params[:action] == "show"
      when :manage
        params[:controller] == "site_elements" && params[:action] == "index"
      else
        false
      end

    active ? "active" : ""
  end

  def sidebar_link_wrapper(link, &block)
    return(capture(&block)) unless current_site

    case link
    when :summary
      link_to(site_path(current_site)){ yield block }
    when :manage
      link_to(site_site_elements_path(current_site)){ yield block }
    else
      capture(&block)
    end
  end
end
