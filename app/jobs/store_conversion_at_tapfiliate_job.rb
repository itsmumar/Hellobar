class StoreConversionAtTapfiliateJob < ApplicationJob
  def perform user
    TapfiliateGateway.new.store_conversion user: user
  end
end
