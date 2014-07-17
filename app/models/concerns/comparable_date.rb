module ComparableDate
  # ComparableDate provides a human readable timestamp.
  # Uses absolute-value offsets to make date barriers sortable.

  # 2000/01/01 +06:00 is Chicago and will always be greater than
  # the same time in LA: 2000/01/01 +04:00.
  # Lexicographic sorting compatible.
  #
  # The formula for finding a timezone's absolute offset is simple:
  # Ordinarily, timezones are represented as + or - based on their side of the date line.
  # Under this system, JST or Japan Standard Time, which is +9 hours, is:
  #
  # 24 - (12 - (+9) = 24 - 3 = +21:00 (please note the '+' is only for formatting and is not significant.)
  # 
  # Los Angeles (PST) is:
  #
  # 24 - (12 - (-8)) = 24 - 20 = +04:00.
  def comparable_start_date
    return unless start_date = value['start_date']
    comparable_date(value['timezone'], start_date)
  end

  def comparable_end_date
    return unless end_date = value['end_date']
    comparable_date(value['timezone'], end_date)
  end

  # Call with either a timezone (will render the current date; tz of nil will default to current user);
  # or a date and a timezone (will use date in that timezone's offset).
  #
  # Output: 2001/01/01 +00:00
  def comparable_date tz=nil, date=nil
    date ||= Time.zone.now.in_time_zone("UTC")
    offset = date.in_time_zone(tz).utc_offset

    date.strftime("%Y/%m/%d").tap do |str|
      str << " +" + comparable_offset(offset) if tz
    end
  end

  # Returns our comparable format - 00:00
  def comparable_offset offset, time=nil
    offset /= 60 * 60 # ruby offsets are in seconds, convert to hours.
    offset += 12 # add the correct number of hours.

    time ||= Time.zone.now
    hours = time.hour + offset
    minutes = time.min

    ("%02d" % hours) + ":" + ("%02d" % minutes)
  end
end
