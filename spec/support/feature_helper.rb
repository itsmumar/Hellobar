RSpec.configure do |config|
  config.include Warden::Test::Helpers

  config.after(:each, type: :feature) do
    Warden.test_reset!
  end
end

module FeatureHelper
  def sign_in(user)
    login_as user, scope: :user, run_callbacks: false

    visit '/'
  end

  def the_onboarding_campaigns_run
    DeliverOnboardingCampaigns.new.call
  end

  def wait_for_ajax
    Timeout.timeout(2) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active')&.zero?
  end

  def bypass_setup_steps(count)
    count.times { scroll_and_click('Next', 'step-wrapper') }
  end

  def submit_form
    find('input[name="commit"]').click
  end

  def mouseleave
    page.execute_script 'document.body.dispatchEvent(new MouseEvent("mouseleave"))'
  end

  private

  def scroll_and_click(link_label, scroll_class)
    page.execute_script("var step = $('.#{ scroll_class }'); step.scrollTop(step.height())")
    page.find('a', text: link_label).click
  end
end
