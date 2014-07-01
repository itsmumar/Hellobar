class SiteElementsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site
  before_filter :load_site_element, :only => [:show, :edit, :update, :destroy, :pause, :unpause]

  layout :determine_layout

  def show
    respond_to do |format|
      format.json { render :json => @site_element, :serializer => SiteElementSerializer }
    end
  end

  def new
    @site_element = Bar.new
  end

  def create
    @site_element = Bar.new(site_element_params)

    if @site_element.valid?
      @site_element.save!
      @site.generate_script
      flash[:success] = "Your bar was successfully created."
      redirect_to site_site_elements_path(:site_id => @site)
    else
      flash.now[:error] = "There was a problem creating your bar."
      render :action => :new
    end
  end

  def update
    if @site_element.update_attributes(site_element_params)
      @site.generate_script
      flash[:success] = "Your bar was successfully updated."
      redirect_to site_site_elements_path(:site_id => @site)
    else
      flash.now[:error] = "There was a problem updating your bar."
      render :action => :edit
    end
  end

  def destroy
    @site_element.destroy
    @site.generate_script
    flash[:success] = "Your bar was successfully deleted."
    redirect_to site_site_elements_path(:site_id => @site)
  end

  def pause
    @site_element.update_attribute(:paused, true)
    @site.generate_script
    redirect_to site_site_elements_path(:site_id => @site)
  end

  def unpause
    @site_element.update_attribute(:paused, false)
    @site.generate_script
    redirect_to site_site_elements_path(:site_id => @site)
  end

  private

  def load_site
    @site = current_user.sites.find(params[:site_id])
  end

  def determine_layout
    %w(edit).include?(action_name) ? "ember" : "with_sidebar"
  end

  def load_site_element
    @site_element = Bar.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @site_element.rule.try(:site) == @site
  end

  def site_element_params
    params.require(:site_element).permit(:rule_id, :bar_type, :message)
  end
end
