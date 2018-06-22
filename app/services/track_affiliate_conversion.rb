class TrackAffiliateConversion
  def initialize user
    @user = user
  end

  def call
    store_conversion
    save_conversion_identifier
  end

  private

  attr_reader :user, :result

  def store_conversion
    @result = affiliate_gateway.store_conversion user: user
  end

  def save_conversion_identifier
    if result.success?
      user.affiliate_information.update conversion_identifier: result['id']
    else
      Rails.logger.error "Tapfiliate error: #{ result['errors'] }"
    end
  end

  def affiliate_gateway
    TapfiliateGateway.new
  end
end
