module EmailDigestHelper
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

  def date_to_index(totals, date)
    i = totals.length - 1 - (Date.today - date).to_i
    i.clamp(0, totals.length - 1)
  end

  def conversions(totals, date=Date.today)
    i = date_to_index(totals, date)
    totals[i][1]
  end

  def views(totals, date=Date.today)
    i = date_to_index(totals, date)
    totals[i][0]
  end

  def conversion_rate(totals, date=Date.today)
    conversions(totals, date) / views(totals, date).to_f
  end
end
