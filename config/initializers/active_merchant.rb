ActiveMerchant::Billing::Base.mode = Rails.env.production? ? :production : :test
