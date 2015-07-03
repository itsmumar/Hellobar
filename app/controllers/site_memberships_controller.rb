class SiteMembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site
  before_action :load_site_membership, :only => [:show, :edit, :update, :destroy]

  def create
    @site_membership = @site.site_memberships.create(site_membership_params)
    if @site_membership.valid?
      render json: @site_membership
    else
      render json: @site_membership.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def update
    if @site_membership.update(site_membership_params)
      render json: @site_membership
    else
      render json: @site_membership.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def destroy
    if @site_membership.destroy
      render json: @site_membership
    else
      render json: @site_membership.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def invite
    user = User.where(email: params[:email]).first
    @site_membership = @site.site_memberships.create(user: user, role: "admin")
    unless @site_membership.valid?
      flash.now[:error] = @site_membership.errors.full_messages
    end
    redirect_to site_team_path(@site)
  end

  private

  def load_site_membership
    @site_membership = @site.site_memberships.find(params[:id])
  end

  def site_membership_params
    params.require(:site_membership).permit(:role, :user_id, :site_id)
  end
end
