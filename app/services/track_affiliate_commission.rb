class TrackAffiliateCommission
  def initialize bill
    @bill = bill
  end

  def call
    return if conversion_identifier.blank?

    store_commission
    create_affiliate_commission
    log_error_if_necessary
  end

  private

  attr_reader :bill, :result

  delegate :subscription, :amount, to: :bill

  def store_commission
    @result = affiliate_gateway.store_commission commission_params
  end

  def create_affiliate_commission
    return unless result.success?

    AffiliateCommission.create!(
      bill: bill,
      identifier: result[0]['id']
    )
  end

  def commission_params
    {
      conversion_identifier: conversion_identifier,
      amount: amount,
      comment: comment
    }
  end

  def user
    subscription&.credit_card&.user
  end

  def comment
    "Paid Bill##{ bill.id } for #{ subscription.type } (#{ subscription.schedule })"
  end

  def conversion_identifier
    user&.affiliate_information&.conversion_identifier
  end

  def log_error_if_necessary
    return if result.success?

    Rails.logger.error "Tapfiliate error: #{ result['errors'] }"
  end

  def affiliate_gateway
    TapfiliateGateway.new
  end
end
