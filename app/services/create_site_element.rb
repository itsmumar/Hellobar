class CreateSiteElement
  def initialize(params, site, current_user)
    @site_element = site.site_elements.build(params)
    @current_user = current_user
    @site = site
  end

  def call
    site_element.save!
    track_event
    generate_script
    site_element
  end

  private

  attr_reader :site_element, :current_user, :site

  def generate_script
    site_element.site.script.generate
  end

  def track_event
    TrackEvent.new(:created_bar, site_element: site_element, user: current_user).call
  end
end
