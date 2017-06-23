module BillingLogger
  mattr_reader :logger do
    file = Rails.root.join('log', 'billing.log')
    logger = ActiveSupport::Logger.new(file)
    @logger = ActiveSupport::TaggedLogging.new(logger)
  end
  private_class_method :logger

  module_function

  def info(*tags, message)
    logger.tagged(*tags) { logger.info message }
  end

  def charge(bill, success)
    info '   PayBill', to_status(success), bill.site.url, "  bill##{ bill.id } $#{ bill.amount }"
  end

  def refund(bill, success)
    info 'RefundBill', to_status(success), bill.site.url, "  bill##{ bill.id } $#{ bill.amount }"
  end

  def credit_card(site, response)
    info ' StoreCard', to_status(response.success?), site.url, "  #{ response.message }"
  end

  def change_subscription(site, props)
    info '    Change', to_status(true), site.url, "  #{ props[:from_plan] }(#{ props[:from_schedule] }) => #{ props[:to_plan] }(#{ props[:to_schedule] })"
  end

  def to_status(success)
    success ? 'success' : '   fail'
  end
end
