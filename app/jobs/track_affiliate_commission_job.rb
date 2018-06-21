class TrackAffiliateCommissionJob < ApplicationJob
  def perform bill
    TrackAffiliateCommission.new(bill).call
  end
end
