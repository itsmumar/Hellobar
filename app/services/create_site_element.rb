class CreateSiteElement
  def initialize(params, site, current_user)
    @site_element = site.site_elements.build(params)
    @current_user = current_user
    @site = site
  end

  def call
    site_element.save!
    track_creation
    generate_script
    site_element
  end

  private

  attr_reader :site_element, :current_user, :site

  def generate_script
    site_element.site.script.generate
  end

  def track_creation
    TrackEvent.new(:created_bar, site_element: site_element, user: current_user).call
    analytics_track_site_element_creation!
    onboarding_track_site_element_creation!
  end

  def analytics_track_site_element_creation!
    Analytics.track(
      :site, site.id, 'Created Site Element',
      site_element_id: site_element.id,
      type: site_element.element_subtype,
      style: site_element.type.to_s.downcase
    )
  end

  def onboarding_track_site_element_creation!
    site.owners.each do |user|
      user.onboarding_status_setter.created_element!
    end
  end
end
