class TrackAffiliateRefund
  def initialize bill
    @bill = bill
    @commission_id = bill.tapfiliate_commission_id
  end

  def call
    return if commission_id.blank?

    disapprove_commission
    log_error_if_necessary
  end

  private

  attr_reader :bill, :commission_id, :result

  def disapprove_commission
    @result = affiliate_gateway.disapprove_commission commission_id: commission_id
  end

  def log_error_if_necessary
    return if result.success?

    Rails.logger.error "Tapfiliate error: #{ result['errors'] }"
  end

  def affiliate_gateway
    TapfiliateGateway.new
  end
end
