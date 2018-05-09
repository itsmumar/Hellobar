class ReferralsController < ApplicationController
  before_action :authenticate_user!, except: [:accept]
  before_action :require_no_user, only: [:accept]

  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_root

  def new
    @referral = current_user.sent_referrals.build
    @referral.set_standard_body
  end

  def index
    @referrals = current_user.sent_referrals.order('updated_at DESC').page(params[:page])
  end

  def create
    @referral = Referrals::Create.run(
      sender: current_user,
      params: referral_params.merge(site_id: current_site.id),
      send_emails: true
    )
    if @referral.valid?
      flash[:success] = I18n.t('referral.flash.created')
      redirect_to referrals_path
    else
      flash[:error] = I18n.t('referral.flash.not_created', error: @referral.errors.full_messages.join(','))
      render action: :new
    end
  rescue Referrals::Create::Error => e
    @referral = current_user.sent_referrals.build(referral_params)
    flash[:error] = e.message
    render action: :new
  end

  def update
    @referral = current_user.sent_referrals.find(params[:id])
    if @referral.update_attributes(referral_params)
      site = Site.unscoped.find_by(id: @referral.site_id)
      RedeemReferralForSender.new(@referral).call if site
      flash[:success] = I18n.t('referral.flash.saved')
    else
      flash[:error] = I18n.t('referral.flash.not_saved')
    end
    redirect_to referrals_path
  end

  def accept
    user = CreateUserFromReferral.new(params[:token]).call
    sign_in(user) if user
    session[:referral_token] = params[:token]
    flash[:success] = I18n.t('referral.flash.accepted')

    redirect_to user ? after_sign_in_path_for(user) : users_sign_up_path
  end

  private

  def referral_params
    params.require(:referral).permit(:email)
  end

  def redirect_to_root
    redirect_to root_url
  end
end
