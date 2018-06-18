class TrackAffiliateConversionJob < ApplicationJob
  def perform user
    TrackAffiliateConversion.new(user).call
  end
end
