class PaymentMethodDetails < ActiveRecord::Base
  belongs_to :payment_method
  serialize :data, JSON

  def readonly?
    new_record? ? false : true
  end

  def name
    raise NotImplementedError
  end
end

require 'active_merchant'
require 'ostruct'

module HB
  class CyberSource
    class BillingAddress < OpenStruct
    end

    class << self
      @gateway = nil
      def gateway
        unless @gateway
          password = "YGxyAaeHOQe2vRoisqdInSI9DE4UEhiOVy5aYpoQewXKcCwF11FZRQncjhOlBU41Qo/MwaQ5vIEMuO/zdFTY+WhXYA8KVgquD2H5mgw/CK470t/oXKHNzzRdfcrYbdChFTloHTSm6TxV/Uo94MzIQSf+38eFYpjkOAei7Fm2esJlm2P3rKCBb10JGMvuE9hJAcJidFJ3qdlw9NzfCEWWzajJ9Wl4/Fc9zRszZ5zbX7oRmCkf/aRDu4nO6gML3wVWj1DkCylLdfYLnbjRFKfF8uHriOo/txJCZRuorM5KkjUTroXAGRq2G40btrXhiQsw4j10Gqa8JJCfM3tvnQoNyg=="
          @gateway = ActiveMerchant::Billing::CyberSourceGateway.new(:login=>"hellobar", :password=>password)
        end
        @gateway
      end
    end
  end
end


class CyberSourceCreditCard < PaymentMethodDetails
  CC_FIELDS = %w{number month year first_name last_name brand}
  ADDRESS_FIELDS = %w{city state zip address1 country}
  FIELDS = CC_FIELDS+ADDRESS_FIELDS 

  def name
    "#{brand ? brand.capitalize : "Credit Card"} ending in #{card.number ? card.number[-4..-1] : "???"}"
  end

  def brand
    card.brand || data["brand"]
  end

  def card
    unless @card
      attributes = {}
      CC_FIELDS.each do |f|
        attributes[f.to_sym] = data[f] || data[f.to_sym]
      end
      @card = ActiveMerchant::Billing::CreditCard.new(attributes)
    end
    @card
  end

  def address
    unless @address
      attributes = {}
      ADDRESS_FIELDS.each do |f|
        attributes[f.to_sym] = data[f] || data[f.to_sym]
      end
      @address = HB::CyberSource::BillingAddress.new(attributes)
    end
    @address
  end

  def data=(new_data)
    sanitized_data = {}
    new_data.each do |key, value|
      key = key.to_s
      if FIELDS.include?(key)
        sanitized_data[key] = value
      end
    end
    write_attribute(:data, sanitized_data)
  end
  
  # Shouldn't really need to get this directly
  def cybersource_profile
    unless @cybersource_profile
      response = HB::CyberSource.gateway.retrieve(formatted_token, {order_id: order_id})
      raise response.message unless response.success?
      @cybersource_profile = response.params
    end
    @cybersource_profile
  end

  def charge(amount_in_dollars)
    raise "Can not charge money until saved" unless persisted? and token
    response = HB::CyberSource.gateway.purchase(amount_in_dollars*100, formatted_token, {order_id: order_id})

    if response.success?
      return true, response.authorization
    else
      return false, response.message
    end
  end

  protected
  def token
    data["token"]
  end
  # ActiveMerchant requires the token in this form
  def formatted_token
    format_token(token)
  end

  def format_token(token)
    ";#{token};"
  end

  def order_id
    # The order_id is fairly irrelevant
    "#{self.payment_method ? self.payment_method.id : "NA"}-#{Time.now.to_i}"
  end

  before_save :save_to_cybersource
  def save_to_cybersource
    user = nil
    if self.payment_method and self.payment_method.user
      user = self.payment_method.user
    end
    # See if there is a previous token
    previous_token = nil
    if self.payment_method
      self.payment_method.details.each do |details|
        if details.is_a?(CyberSourceCreditCard)
          if details.data["token"]
            previous_token = details.data["token"]
          end
        end
      end
    end
    response = nil
    # Note: we don't want to give CyberSource our customer's email addresses,
    # which is why we use the generic userXXX@hellobar.com format
    email = "user#{user ? user.id : "NA"}@hellobar.com"
    params = {:order_id=>order_id, :email => email, :address=>address.to_h}
    if previous_token
      # Update the profile
      response = HB::CyberSource::gateway.update(format_token(previous_token), card, params)
    else
      # Create a new profile
      response = HB::CyberSource.gateway.store(card, params)
    end
    raise response.message unless response.success?
    data["token"] = response.params["subscriptionID"]
    # Set the brand
    data["brand"] = card.brand
    data["number"] = "XXXX-XXXX-XXXX-"+data["number"][-4..-1]
    # Clear the card attribute so it clears the cache of the number
    @card = nil
  end
end
