class UserMigrationController < ApplicationController
  layout 'static'
  before_filter :verify_wordpress_user

  def new
    @bars = [current_wordpress_user.bars.first]
  end

  def create
    if params[:bar_ids].blank? && params[:bar_id].present? && params[:site][:url].present?
      params[:bar_ids] = {params[:site][:url] => [params[:bar_id]]}
    end

    ActiveRecord::Base.transaction do
      user = current_wordpress_user.convert_to_user

      params[:bar_ids].each do |url, ids|
        Site.new(url: url).tap do |site|
          site.save!
          site.create_default_rule

          SiteMembership.create!(site: site, user: user)

          ids.each do |id|
            if bar = load_wordpress_bar(id)
              bar.convert_to_site_element!(site.rules.first)
            end
          end

          sub = site.site_elements.count >= 10 ? Subscription::FreePlus.new(schedule: "monthly") : Subscription::Free.new(schedule: "monthly")
          site.change_subscription(sub)
        end
      end

      sign_in(user)
    end

    session[:wordpress_user_id] = nil
    url = current_user.sites.any? ? site_site_elements_path(current_user.sites.first, anchor: "upgrade-modal") : new_site_path

    respond_to do |format|
      format.json { render json: { url: url } }
      format.html { redirect_to url }
    end
  end

  private

  def verify_wordpress_user
    return redirect_to(new_user_session_path) unless current_wordpress_user
  end

  def current_wordpress_user
    return @wordpress_user if @wordpress_user

    if session[:wordpress_user_id] && @wordpress_user = Hello::WordpressUser.where(id: session[:wordpress_user_id]).first
      return @wordpress_user
    end
  end

  def load_wordpress_bar(id)
    bar = Hello::WordpressBar.find(id)
    bar.post_author == current_wordpress_user.id ? bar : nil
  end
end
