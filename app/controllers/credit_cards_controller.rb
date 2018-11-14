class CreditCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site
  before_action :load_partner_plan, only: %i[new create]
  skip_before_action :require_credit_card

  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def index
    subscription_credit_card_id = @site.current_subscription.credit_card_id if @site

    response = {
      credit_cards: current_user.credit_cards.map { |credit_card| CreditCardSerializer.new(credit_card).as_json },
      current_credit_card_id: subscription_credit_card_id
    }

    respond_to do |format|
      format.json { render json: response }
    end
  end

  def new
    @form = PaymentForm.new(params[:credit_card])

    @hide_logo = @partner_plan ? true : false
    render layout: 'static'
  end

  def create
    @form = PaymentForm.new(params[:credit_card])
    @site ||= current_site
    credit_card = CreateCreditCard.new(@site, current_user, params).call
    check_for_utm_campaign
    if @form.plan.present?
      ChangeSubscription.new(@site, { subscription: @form.plan_name, schedule: @form.plan_schedule }, credit_card).call
      redirect_to new_site_site_element_path(@site)
    else
      respond_to do |format|
        format.html { redirect_to after_sign_in_path_for(current_user) }
        format.json { render json: credit_card }
      end
    end
  end

  private

  def record_invalid(error)
    respond_to do |format|
      format.html do
        if @form.plan.present?
          flash[:error] = error.record.errors.full_messages.to_sentence
          redirect_to subscribe_registration_path(@form.plan)
        else
          flash.now[:error] = error.record.errors.full_messages.to_sentence
          render :new, layout: 'static'
        end
      end
      format.json do
        Raven.capture_exception(error.record.errors.full_messages.to_sentence, extra: { full_response: error.record.errors.full_messages })
        render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def load_partner_plan
    @partner_plan = current_user.affiliate_information&.partner&.partner_plan
  end

  def check_for_utm_campaign
    TrackEvent.new(:pricing_page_conversion, site: @site, user: current_user).call if cookies[:utm_campaign] == 'pricing'
  end
end
