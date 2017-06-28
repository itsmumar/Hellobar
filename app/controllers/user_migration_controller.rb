class UserMigrationController < ApplicationController
  layout 'static'
  before_action :verify_wordpress_user, except: %i[upgrade start]

  def new
    @bars = current_wordpress_user.bars
  end

  def start
    email = params[:email]
    password = params[:password]

    if User.where(email: email).exists?
      redirect_to login_path, notice: 'This email has already been upgraded.  Please log in.'
    elsif (wordpress_user = Hello::WordpressUser.authenticate(email, password, current_admin.present?))
      session[:wordpress_user_id] = wordpress_user.id
      redirect_to new_user_migration_path
    else
      flash.now[:error] = 'Invalid email or password'
      render action: :upgrade
    end
  end

  def create
    site_hashes =
      if params[:sites].present?
        params[:sites].map { |_, v| v }
      elsif params[:site].present?
        [{
          url: params[:site][:url],
          timezone: params[:site][:timezone],
          bar_ids: [params[:bar_id]]
        }]
      end

    ActiveRecord::Base.transaction do
      user = current_wordpress_user.convert_to_user

      site_hashes.each do |site_hash|
        Site.new(url: site_hash[:url], timezone: site_hash[:timezone]).tap do |site|
          site.save!
          site.create_default_rules

          SiteMembership.create!(site: site, user: user)

          subscription = Subscription::Pro.new(schedule: 'monthly')
          site.change_subscription(subscription, nil, Hello::WordpressUser::PRO_TRIAL_PERIOD)

          site_hash[:bar_ids].each do |id|
            if (bar = load_wordpress_bar(id))
              bar.convert_to_site_element!(site.rules.first)
            end
          end

          DetectInstallType.new(site).call
        end
      end

      sign_in(user)
    end

    session[:wordpress_user_id] = nil
    url = current_user.sites.any? ? site_site_elements_path(current_user.sites.first, anchor: 'migration-complete') : new_site_path
    current_user.sites.each(&:generate_script)

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
    return unless session[:wordpress_user_id] && (@wordpress_user = Hello::WordpressUser.find_by(id: session[:wordpress_user_id]))

    @wordpress_user
  end

  def load_wordpress_bar(id)
    bar = Hello::WordpressBar.find(id)
    bar.post_author == current_wordpress_user.id ? bar : nil
  end
end
