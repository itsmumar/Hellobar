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
    onboarding_track_site_element_creation!
  end

  def onboarding_track_site_element_creation!
    site.owners.each do |user|
      # lets cheat the onboarding nonsense; moved here from the deleted TrackingController
      # we are moving `create_a_bar` drip campaign mailer to Intercom
      # and we will just delete `configure_your_bar` one
      # https://crossover.atlassian.net/browse/XOHB-2550
      user.onboarding_status_setter.selected_goal!

      user.onboarding_status_setter.created_element!
    end
  end
end
