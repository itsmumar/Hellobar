class AutofillsController < ApplicationController

  before_action :authenticate_user!
  before_action :load_site
  before_action :load_autofill, only: [:edit, :update, :destroy]

  def index
    @autofills = Autofill.where(site_id: @site.id).order name: :asc
  end

  def new
    @autofill = Autofill.new site_id: @site.id
  end

  def create
    @autofill = Autofill.new autofill_params

    if @autofill.save
      flash[:success] = 'Autofill was successfully created.'
      redirect_to site_autofills_path @site
    else
      flash.now[:error] = @autofill.errors.full_messages
      render :new
    end
  end

  def edit
  end

  def update
    if @autofill.update autofill_params
      flash[:success] = 'Autofill was successfully updated.'
      redirect_to site_autofills_path @site
    else
      flash.now[:error] = @autofill.errors.full_messages
      render :edit
    end
  end

  def destroy
    @autofill.destroy
    flash[:success] = 'Autofill was successfully deleted.'
    redirect_to site_autofills_path @site
  end

  private

  def load_autofill
    @autofill = Autofill.where(site_id: @site.id).find params[:id]
  end

  def autofill_params
    params.
      require(:autofill).
      permit(:name, :listen_selector, :populate_selector).
      merge site_id: @site.id
  end
end
