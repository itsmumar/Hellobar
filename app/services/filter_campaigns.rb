class FilterCampaigns
  FILTERS = {
    draft: 'Draft',
    sent: 'Sent',
    archived: 'Archived',
    deleted: 'Deleted'
  }.with_indifferent_access.freeze

  DEFAULT_FILTER = :draft

  def initialize(params)
    @params = params
  end

  def call
    { campaigns: fetch_campaigns, filters: build_filters }
  end

  private

  attr_reader :params

  def filter
    @filter ||= FILTERS.key?(params[:filter]) ? params[:filter] : DEFAULT_FILTER
  end

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
