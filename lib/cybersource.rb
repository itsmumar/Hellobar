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
          ActiveMerchant::Billing::Base.mode = Hellobar::Settings[:cybersource_environment].try(:to_sym) || :test
          @gateway = ActiveMerchant::Billing::CyberSourceGateway.new(:login=>Hellobar::Settings[:cybersource_login], :password=>Hellobar::Settings[:cybersource_password], :ignore_avs=>true)
        end
        @gateway
      end
    end
  end
end


class CyberSourceCreditCard < PaymentMethodDetails
  CC_FIELDS = %w{number month year first_name last_name brand verification_value}
  ADDRESS_FIELDS = %w{city state zip address1 country}
  # Note: any fields not included here will be stripped out when setting
  FIELDS = CC_FIELDS+ADDRESS_FIELDS+["token"]
  # These are the required fields to be set
  REQUIRED_FIELDS = FIELDS-%w{brand token state}

  class CyberSourceCreditCardValidator < ActiveModel::Validator
    def validate(record)
      REQUIRED_FIELDS.each do |field|
        if !record.data or record.data[field].blank?
          record.errors[field.to_sym] = "can not be blank"
        end
      end
      begin
        record.send(:save_to_cybersource)
      rescue Exception => e
        record.errors[:base] = e.message
      end
    end
  end
  validates_with CyberSourceCreditCardValidator

  def name
    "#{brand ? brand.capitalize : "Credit Card"} ending in #{card.number ? card.number[-4..-1] : "???"}"
  end

  def grace_period
    15.days
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
    if amount_in_dollars == 0
      return true, "Amount was zero"
    end
    if !amount_in_dollars or amount_in_dollars < 0
      raise "Invalid amount: #{amount_in_dollars.inspect}"
    end
    begin
      response = HB::CyberSource.gateway.purchase(amount_in_dollars*100, formatted_token, {order_id: order_id})

      audit << "Charging #{amount_in_dollars.inspect}, got response: #{response.inspect}"
      if response.success?
        return true, response.authorization
      else
        return false, response.message
      end
    rescue Exception => e
      audit << "Error charging #{amount_in_dollars.inspect}: #{e.message}"
      raise
    end
  end

  def refund(amount_in_dollars, original_transaction_id)
    raise "Can not refund money until saved" unless persisted? and token
    if amount_in_dollars == 0
      return true, "Amount was zero"
    end
    if !amount_in_dollars or amount_in_dollars < 0
      raise "Invalid amount: #{amount_in_dollars.inspect}"
    end
    if !original_transaction_id
      raise "Can not refund without original transaction ID"
    end
    begin
      response = HB::CyberSource.gateway.refund(amount_in_dollars*100, original_transaction_id)

      audit << "Refunding #{amount_in_dollars.inspect} to #{original_transaction_id.inspect}, got response: #{response.inspect}"
      if response.success?
        return true, response.authorization
      else
        return false, response.message
      end
    rescue Exception => e
      audit << "Error refunding #{amount_in_dollars.inspect} to #{original_transaction_id.inspect}: #{e.message}"
      raise
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

  def save_to_cybersource
    user = nil
    if self.payment_method and self.payment_method.user
      user = self.payment_method.user
    end
    # See if there is a previous token
    previous_token = nil
    if self.payment_method
      self.payment_method.details(true).each do |details|
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
    # Set the brand
    data["brand"] = card.brand

    data["sanitized_number"] = "XXXX-XXXX-XXXX-"+data["number"][-4..-1]
    sanitized_data = data.clone
    sanitized_data.delete("number")
    sanitized_data.delete("verification_value")

    begin
      if previous_token
        # Update the profile
        response = HB::CyberSource::gateway.update(format_token(previous_token), card, params)
        audit << "Updated previous_token: #{previous_token.inspect} with #{sanitized_data.inspect} response: #{response.inspect}"
      else
        # Create a new profile
        response = HB::CyberSource.gateway.store(card, params)
        audit << "Create new token with #{sanitized_data.inspect} response: #{response.inspect}"
      end
      unless response.success?
        if field = response.params["invalidField"]
          if field == "c:cardType"
            raise "Invalid credit card"
          else
            raise "Invalid #{field.gsub(/^c:/,"").underscore.humanize.downcase}"
          end
        end
        raise response.message
      end
    rescue Exception => e
      audit << "Error tokenizing with #{sanitized_data.inspect} response: #{response.inspect} error: #{e.message}"
      raise
    end
    data["number"] = data.delete("sanitized_number")
    data.delete("verification_value")
    data["token"] = response.params["subscriptionID"]
    # Clear the card attribute so it clears the cache of the number
    @card = nil
  end
end

