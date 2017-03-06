class TargetedSegmentsController < ApplicationController
  include TargetedSegmentsHelper

  before_action :authenticate_user!
  before_action :load_site

  helper_method :generate_segment_token

  def create
    generated_token = generate_segment_token(params[:targeted_segment][:segment])

    if generated_token == params[:targeted_segment][:token]
      @rule = Rule.create_from_segment(@site, params[:targeted_segment][:segment])
    end

    if @rule && @rule.valid?
      redirect_to new_site_site_element_path(@site, anchor: "/settings?rule_id=#{ @rule.id }")
    else
      flash[:error] = 'Sorry, but there was an error creating your segment. Please try again.'
      redirect_to site_improve_path(@site)
    end
  end
end
