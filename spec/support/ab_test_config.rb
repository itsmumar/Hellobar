RSpec.configure do |config|
  config.before(:each) do
    # allow us to register which get_ab_variation calls we stubbing,
    # let the rest of the calls pass through to ApplicationController untouched
    allow_any_instance_of(ApplicationController).to receive(:get_ab_variation).and_call_original

    allow_any_instance_of(SiteSerializer).
      to receive(:monthly_pageviews).and_return(nil)

    stub_out_get_ab_variations('Targeting UI Variation 2016-06-13') { 'original' }
    stub_out_get_ab_variations('Exit Intent Pop-up Based on Bar Goals 2016-06-08') { 'original' }
    stub_out_get_ab_variations('Onboarding Email Volume 2016-06-28') { 'original' }
    stub_out_get_ab_variations('Pricing Modal Copy 2016-07-07') { 'original' }
    stub_out_get_ab_variations('Email Integration UI 2016-06-22') { 'original' }
  end
end

def stub_out_get_ab_variations(*variations, &result)
  variation_matcher = Regexp.new(variations.join('|'))

  allow_any_instance_of(ApplicationController).
    to receive(:get_ab_variation).
    with(variation_matcher).
    and_return(result.call)

  allow_any_instance_of(ApplicationController).
    to receive(:get_ab_variation).
    with(variation_matcher, anything).
    and_return(result.call)

  allow_any_instance_of(ApplicationController).
    to receive(:get_ab_variation_or_nil).
    with(variation_matcher).
    and_return(result.call)
end
