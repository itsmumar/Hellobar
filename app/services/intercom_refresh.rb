class IntercomRefresh
  def initialize(current_user)
    @current_user = current_user
    @site = site
  end

  def call
    refresh
    # site_element
  end

  private

  attr_reader :current_user, :site

  def refresh
    
  end

  # def track_event
  #   TrackEvent.new(:created_bar, site_element: site_element, user: current_user).call
  # end
end
