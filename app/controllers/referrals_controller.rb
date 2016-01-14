class ReferralsController < ApplicationController
  before_action :authenticate_user!, except: [:accept]

  def new
    @referral = current_user.sent_referrals.build
    @referral.set_standard_body
  end

  def index
    @referrals = current_user.sent_referrals.order("updated_at DESC").page(params[:page])
  end

  def create
    @referral = Referrals::Create.run(
      sender: current_user,
      params: referral_params,
      send_emails: true
    )
    if @referral.valid?
      flash[:success] = I18n.t('referral.created')
    else
      flash[:error] = I18n.t('referral.not_created')
    end
    redirect_to referrals_path
  end

  def update
    @referral = current_user.sent_referrals.find(params[:id])
    if @referral.update_attributes(referral_params)
      Referrals::RedeemForSender.run(site: @referral.site) if @referral.site
      flash[:success] = I18n.t('referral.saved')
    else
      flash[:error] = I18n.t('referral.not_saved')
    end
    redirect_to referrals_path
  end

  def accept
    token = ReferralToken.where(token: params[:token]).first
    if current_user.blank? && token.present?
      session[:referral_token] = params[:token]
      flash[:success] = I18n.t('referral.accepted')
    else
      # Either they're already in the app, in which case the referral doesn't apply,
      # or the token is wrong. In both cases, just redirect them.
    end
    redirect_to root_path
  end

  private

  def referral_params
    params.require(:referral).permit(:email, :body, :site_id)
  end
end
