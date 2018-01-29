# This implements the same interface as ActiveModel::Serializer does but it's not inherited
# from ActiveModel::Serializer because it doesn't provide flexibility that we need here.
# Once `active_model_serializers` gem is migrated to v0.10 we can do it more elegant by overriding
# method `read_attribute_for_serialization`.
class CampaignsSerializer
  def initialize(campaigns, _options = {})
    @campaigns = campaigns
  end

  def as_json(_options = {})
    { campaigns: serialize_campaigns, filters: serialize_filters }
  end

  private

  def serialize_campaigns
    @campaigns[:campaigns].map { |campaign| CampaignSerializer.new(campaign) }
  end

  def serialize_filters
    @campaigns[:filters]
  end
end
