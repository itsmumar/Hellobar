class BillsController < ApplicationController
  before_action :authenticate_user!

  def show
    @bill = Bill.find(params[:id])
    raise(ActiveRecord::RecordNotFound) unless @bill.site.owner == current_user
  end
end
