class PagesController < ApplicationController

  layout 'static'

  def use_cases
    @amount_of_use_cases = get_ab_variation("Use Cases Amount")
  end

  def terms_of_use
    Analytics.track(*current_person, "Viewed Terms of Use")
  end

  def privacy_policy
  end

  def logout_confirmation
  end
end
