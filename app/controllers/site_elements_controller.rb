class SiteElementsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site
  before_filter :load_site_element, :only => [:edit, :update]

  layout "with_sidebar"

  def new
    @site_element = Bar.new
  end

  def create
    @site_element = Bar.new(site_element_params)

    if @site_element.valid?
      @site_element.save!
      flash[:success] = "Your bar was successfully created."
      redirect_to site_site_elements_path(:site_id => @site)
    else
      flash.now[:error] = "There was a problem creating your bar."
      render :action => :new
    end
  end

  def update
    if @site_element.update_attributes(site_element_params)
      flash[:success] = "Your bar was successfully updated."
      redirect_to site_site_elements_path(:site_id => @site)
    else
      flash.now[:error] = "There was a problem updating your bar."
      render :action => :edit
    end
  end


  private

  def load_site
    @site = current_user.sites.find(params[:site_id])
  end

  def load_site_element
    @site_element = Bar.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @site_element.rule_set.try(:site) == @site
  end

  def site_element_params
    params.require(:site_element).permit(:rule_set_id, :goal)
  end
end
