class FilterCampaigns
  FILTERS = %i[sent drafts archived].freeze
  DEFAULT_FILTER = :sent

  def initialize site, params = {}
    @site = site
    @filter = params[:filter]&.to_sym
    @filter = DEFAULT_FILTER unless @filter.in? FILTERS
  end

  def call
    [campaigns, statistics]
  end

  private

  attr_reader :site, :filter

  def scope_for(filter)
    site.campaigns.with_emails.public_send(filter)
  end

  def campaigns
    @campaigns ||= scope_for(filter).to_a
  end

  def statistics
    FILTERS.each.with_object(total: site.campaigns.size) do |filter, stats|
      stats[filter] = scope_for(filter).size
    end
  end
end
