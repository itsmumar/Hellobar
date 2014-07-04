module EmailDigestHelper
  def element_activity_units(elements, opts = {})
    units = [*elements].map do |element|
      case element.element_subtype
      when "traffic"
        {:unit => "click"}
      when "email"
        {:unit => "email"}
      when "social/tweet_on_twitter"
        {:unit => "tweet"}
      when "social/follow_on_twitter"
        {:unit => "follower"}
      when "social/like_on_facebook"
        {:unit => "like"}
      when "social/share_on_linkedin"
        {:unit => "share"}
      when "social/plus_one_on_google_plus"
        {:unit => "plus one"}
      when "social/pin_on_pinterest"
        {:unit => "pin"}
      when "social/follow_on_pinterest"
        {:unit => "follower"}
      when "social/share_on_buffer"
        {:unit => "share"}
      end
    end

    unit = units.uniq.size == 1 ? units.first[:unit] : "action"
    unit.pluralize(opts[:plural] ? 2 : 1)
  end

  def formatted_percent_with_wrapper(percent, opts = {})
    if percent.nil? || percent == 0
      style = "color: gray"
      direction = nil
    elsif percent > 0
      style = "color: green"
      direction = "+"
    else
      style = "color: red"
      direction = nil
    end

    if percent.nil?
      formatted = "n/a%"
    else
      formatted = number_to_percentage(percent * 100, :precision => 2)
    end

    "<span style=\"#{style}\">".tap do |output|
      output << "(" if opts[:parens]
      output << direction if direction
      output << formatted
      output << ")" if opts[:parens]

      output << "</span>"
    end.html_safe
  end
end
