# readable BigDecimal#inspect output (https://gist.github.com/henrik/6280438)
class BigDecimal
  def inspect
    format('#<BigDecimal:%x %s>', object_id, to_s('F'))
  end
end
