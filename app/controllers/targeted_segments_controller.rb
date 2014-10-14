class TargetedSegmentsController < ApplicationController
  SALT = "7f9d074257b1400c55d0b838d8e7f5bdd8330151"

  before_action :authenticate_user!
  before_action :load_site

  helper_method :generate_segment_token

  def create
    generated_token = generate_segment_token(params[:targeted_segment][:segment])

    if generated_token == params[:targeted_segment][:token]
      @rule = Rule.create_from_segment(params[:targeted_segment][:segment])
    end

    if @rule && @rule.valid?
      redirect_to new_site_site_element_path(@site, :anchor => "/settings?rule_id=#{@rule.id}")
    else
      flash[:error] = "Sorry, but there was an error creating your segment. Please try again."
      redirect_to site_improve_path(@site)
    end
  end

  private

  def load_site
    @site = current_user.sites.find(params[:site_id])
  end

  def generate_segment_token(segment)
    Digest::SHA1.hexdigest("#{SALT}#{segment}")
  end
end
