class SiteMembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site
  before_action :load_site_membership, only: %i[show edit update destroy]

  def create
    site_membership = @site.site_memberships.create(site_membership_params)

    if site_membership.valid?
      TrackEvent.new(:invited_member, site: @site, user: current_user).call
      TeamMailer.invite(site_membership).deliver_later

      render json: site_membership
    else
      render json: { site_memberships: site_membership.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @site_membership.update(site_membership_params)
      render json: @site_membership
    else
      render json: { site_memberships: @site_membership.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @site_membership.user == current_user
      render json: { site_memberships: ["Can't remove permissions from yourself."] }, status: :unprocessable_entity
    elsif @site_membership.can_destroy? && @site_membership.destroy
      render json: @site_membership
    else
      render json: { site_memberships: @site_membership.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def invite
    user = User.find_or_invite_by_email(params[:email], @site)
    notice = nil

    if user.valid?
      site_membership = @site.site_memberships.create(user: user, role: 'admin')

      if site_membership.valid?
        TeamMailer.invite(site_membership).deliver_later
        notice = "#{ user.email } has been invited to #{ @site.url }."
      else
        notice = site_membership.errors.full_messages.join('. ')
      end
    else
      notice = user.errors.full_messages.join('. ')
    end

    redirect_to site_team_path(@site), notice: notice
  end

  private

  def load_site_membership
    @site_membership = @site.site_memberships.find(params[:id])
  end

  def site_membership_params
    params.require(:site_membership).permit(:role, :user_id, :site_id).merge(updated_by: current_user)
  end
end
