class DateRule < Rule
  # { start_date: <DateTime>, end_date: <DateTime> }
  serialize :value, Hash
end
