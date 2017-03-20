include Warden::Test::Helpers

Warden.test_mode!

RSpec.configure do |config|
  config.after(:each, type: :feature) do
    Warden.test_reset!
  end
end

module FeatureHelper
  def login(user = nil)
    user ||= create(:user)
    unless user.sites.present?
      user.sites.create(url: random_uniq_url) # Setup a site so that it goes directly to summary page
    end

    login_as user, scope: :user, run_callbacks: false
    visit '/'
    user
  end

  def the_onboarding_campaigns_run
    UserOnboardingCampaign.deliver_all_onboarding_campaign_email!
  end

  def wait_for_ajax
    Timeout.timeout(2) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end

  def bypass_setup_steps(count)
    count.times { scroll_and_click('Next', 'step-wrapper') }
  end

  def submit_form
    find('input[name="commit"]').click
  end

  private

  def scroll_and_click(link_label, scroll_class)
    page.execute_script("var step = $('.#{ scroll_class }'); step.scrollTop(step.height())")
    page.find('a', text: link_label).click
  end
end
