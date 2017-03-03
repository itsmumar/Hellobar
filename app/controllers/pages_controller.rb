class PagesController < ApplicationController
  layout 'static'

  def use_cases
  end

  def terms_of_use
    Analytics.track(*current_person_type_and_id, "Viewed Terms of Use")
  end

  def privacy_policy
  end

  def migrate_faq
  end

  def logout_confirmation
  end
end
