class BillsController < ApplicationController
  before_action :authenticate_user!

  def show
    @bill = Bill.find(params[:id])
    @site = Site.unscoped.find(@bill.site_id)
    @credit_card = @bill.successful_billing_attempt&.credit_card
    raise ActiveRecord::RecordNotFound if !Permissions.view_bills?(current_user, @site) || @bill.problem?
    render layout: 'receipt'
  end
end
