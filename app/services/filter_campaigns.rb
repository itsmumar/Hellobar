class FilterCampaigns
  FILTERS = {
    draft: 'Draft',
    sent: 'Sent',
    archived: 'Archived',
    deleted: 'Deleted'
  }.freeze

  DEFAULT_FILTER = :draft

  def initialize(params)
    @filter = params[:filter].try(:to_sym)
    @filter = DEFAULT_FILTER unless FILTERS[@filter]
  end

  def call
    { campaigns: fetch_campaigns, filters: build_filters }
  end

  private

  attr_reader :filter

  def scope_for(filter)
    Campaign.public_send(filter)
  end

  def fetch_campaigns
    @campaigns ||= scope_for(filter).to_a
  end

  def build_filters
    FILTERS.map do |key, title|
      active = key == filter

      {
        key: key,
        title: title,
        active: active,
        count: active ? fetch_campaigns.size : scope_for(key).count
      }
    end
  end
end
