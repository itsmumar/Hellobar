class PagesController < ApplicationController

  layout 'static'

  def use_cases
  end

  def terms_of_use
  end

  def privacy_policy
  end

  def logout_confirmation
    flash.delete(:notice) # dont render the logout flash
  end
end
