class StoreCommissionAtTapfiliateJob < ApplicationJob
  def perform bill
    TapfiliateGateway.new.store_commission bill: bill
  end
end
