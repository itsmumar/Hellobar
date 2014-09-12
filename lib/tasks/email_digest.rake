class ViewHelper
  include ActionView::Helpers
  include EmailDigestHelper
  include SitesHelper
end

namespace :email_digest do
  task :load_dependencies do
    include Hellobar::Application.routes.url_helpers
    @helper = ViewHelper.new
  end

  task :deliver_installed => [:environment, :load_dependencies] do
    Hello::EmailDigest.installed_sites.each do |site|
      next unless user = site.owner

      email_name = Hello::EmailDigest.email_name(site)
      metrics = Hello::EmailDigest.site_metrics(site)

      create_bar_url = new_site_site_element_url(:site_id => site, :host => "www.hellobar.com", :trk => Hello::TrackingParam.encode_tracker(user.id, "click", "#{email_name}_create_bar_cta"))
      create_bar_button_url = new_site_site_element_url(:site_id => site, :host => "www.hellobar.com", :trk => Hello::TrackingParam.encode_tracker(user.id, "click", "#{email_name}_create_bar_button"))
      unsubscribe_url = edit_site_url(site, :host => "www.hellobar.com", :trk => Hello::TrackingParam.encode_tracker(user.id, "click", "#{email_name}_unsubscribe"))

      params = {
        :site_url => @helper.display_url_for_site(site),
        :start_date => 7.days.ago.strftime("%B %-d"),
        :end_date => 1.day.ago.strftime("%B %-d, %Y"),
        :tracking_pixel => tracking_pixel_url(:host => "www.hellobar.com", :trk => Hello::TrackingParam.encode_tracker(user.id, "open", email_name)),
        :create_bar_cta => Hello::EmailDigest.create_bar_cta(site, metrics, create_bar_url),
        :create_bar_button_url => create_bar_button_url,
        :unsubscribe_url => unsubscribe_url
      }

      if metrics[:total].nil?
        params[:total_views] = 0
        params[:total_actions] = 0
        params[:total_conversion] = 0
        params[:total_views_lift] = @helper.formatted_percent_with_wrapper(nil)
        params[:total_actions_lift] = @helper.formatted_percent_with_wrapper(nil)
        params[:total_conversion_lift] = @helper.formatted_percent_with_wrapper(nil)
      else
        params[:total_views] = @helper.number_with_delimiter(metrics[:total][:views][:n])
        params[:total_actions] = @helper.number_with_delimiter(metrics[:total][:actions][:n])
        params[:total_conversion] = @helper.number_to_percentage(metrics[:total][:conversion][:n] * 100, :precision => 2)
        params[:total_views_lift] = @helper.formatted_percent_with_wrapper(metrics[:total][:views][:lift])
        params[:total_actions_lift] = @helper.formatted_percent_with_wrapper(metrics[:total][:actions][:lift])
        params[:total_conversion_lift] = @helper.formatted_percent_with_wrapper(metrics[:total][:conversion][:lift])
      end

      [:traffic, :email, :social].each do |bar_type|
        bar_data = metrics[bar_type]

        if bar_data.nil?
          params["#{bar_type}_row_header".to_sym] = "<span style='color: gray'>#{bar_type.capitalize} bars</span>"
          params["#{bar_type}_views".to_sym] =      "<big style='color: gray'>-</big>"
          params["#{bar_type}_actions".to_sym] =    "<big style='color: gray'>-</big>"
          params["#{bar_type}_conversion".to_sym] = "<big style='color: gray'>-</big>"
        else
          params["#{bar_type}_row_header".to_sym] = "#{bar_type.capitalize} bars"
          params["#{bar_type}_views".to_sym] = "<big>#{@helper.number_with_delimiter(bar_data[:views][:n])}</big> <small>#{@helper.formatted_percent_with_wrapper(bar_data[:views][:lift], :parens => true)}</small>"
          params["#{bar_type}_actions".to_sym] = "<big>#{@helper.number_with_delimiter(bar_data[:actions][:n])}</big> <small>#{@helper.formatted_percent_with_wrapper(bar_data[:actions][:lift], :parens => true)}</small>"
          params["#{bar_type}_conversion".to_sym] = "<big>#{@helper.number_to_percentage(bar_data[:conversion][:n] * 100, :precision => 2)}</big> <small>#{@helper.formatted_percent_with_wrapper(bar_data[:conversion][:lift], :parens => true)}</small>"
        end
      end

      # Grand Central only accepts string parameters
      params.each{|k,v| params[k] = v.to_s}

      MailerGateway.send_email("Email Digest", user.email, params)
      Hello::EmailDigest.track_send(user, email_name)
    end
  end

  task :deliver_not_installed => [:environment, :load_dependencies] do
    Hello::EmailDigest.not_installed_sites.each do |site|
      next unless user = site.account.try(:payer)

      email_name = Hello::EmailDigest.email_name(site)
      unsubscribe_url = site_settings_url(site, :host => "www.hellobar.com", :trk => Hello::EmailDrip.encode_tracker(user.id, "click", "#{email_name}_unsubscribe"))

      params = {
        :site_url => site.short_url,
        :tracking_pixel => tracking_pixel_url(:host => "www.hellobar.com", :trk => Hello::EmailDrip.encode_tracker(user.id, "open", email_name)),
        :unsubscribe_url => unsubscribe_url
      }

      if site.bars.any?
        params[:install_url] = edit_bar_url(site.bars.first, :host => "www.hellobar.com", :anchor_redirect => "install", :trk => Hello::EmailDrip.encode_tracker(user.id, "click", "#{email_name}_install"))
      else
        params[:install_url] = site_url(site, :host => "www.hellobar.com", :trk => Hello::EmailDrip.encode_tracker(user.id, "click", "#{email_name}_install"))
      end

      MailerGateway.send_email("Email Digest (Not Installed)", user.email, params)
      Hello::EmailDigest.track_send(user, email_name)
    end
  end
end
