class SiteElementsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site
  before_filter :load_site_element, :only => [:show, :edit, :update, :destroy, :pause, :unpause]

  layout :determine_layout

  def show
    render :json => @site_element
  end

  def new
    @site_element = SiteElement.new
  end

  def create
    @site_element = SiteElement.new(site_element_params)

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
      render :json => @site_element
    else
      render :json => @site_element.errors, :status => :unprocessable_entity
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
    @site_element = @site.site_elements.find(params[:id])
  end

  def site_element_params
    settings_keys = [:url, :collect_names, :url_to_tweet, :message_to_tweet, :twitter_handle, :url_to_like, :url_to_share, :url_to_plus_one, :pinterest_url, :pinterest_image_url, :pinterest_description, :pinterest_user_url, :pinterest_full_name, :buffer_url, :buffer_message]
    params.require(:site_element).permit(:rule_id, :element_subtype, :message, :background_color, :border_color, :button_color, :font, :link_color, :link_text, :text_color, {:settings => settings_keys})
  end
end
