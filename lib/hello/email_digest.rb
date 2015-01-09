module Hello::EmailDigest
  class << self
    include EmailDigestHelper
    include SiteElementsHelper
    include SitesHelper
    include ActionView::Helpers
    include Hellobar::Application.routes.url_helpers

    def installed_sites
      Site.where("script_installed_at IS NOT NULL").where(:opted_in_to_email_digest => true)
    end

    def not_installed_sites
      Site.where(:script_installed_at => nil, :opted_in_to_email_digest => true).where("created_at > ?", 4.weeks.ago)
    end

    def email_name(site)
      if site.script_installed_at.nil?
        installed = "not_installed"
        week = ((Time.now - site.created_at) / 1.week).floor + 1
      else
        installed = "installed"
        week = ((Time.now - site.script_installed_at) / 1.week).floor + 1
      end

      version = "v1"
      "#{installed}_#{version}_w#{week}"
    end

    def track_send(user, email_name)
=begin
      InternalEvent.create(
        :timestamp => Time.now.to_i,
        :target_id => user.id,
        :target_type=>"user",
        :name => "Sent email digest: #{email_name}"
      )
=end
    end

    def site_metrics(site)
      api_data = Hello::DataAPI.lifetime_totals_by_type(site, site.site_elements, 16)

      {}.tap do |metrics|
        api_data.each { |k, v| metrics[k] = metrics_for_data_subset(v) }
      end
    end

    def metrics_for_data_subset(data)
      # we have to start with yesterday's data, since today will never be a full day's worth
      return nil if data.count < 2

      initial = data[-16] || [0, 0] # the total views and conversions immediately before the period we're sampling
      last_week = data[-9] || [0, 0]
      last_week = [last_week[0] - initial[0], last_week[1] - initial[1]]
      this_week = [data[-2][0] - last_week[0] - initial[0], data[-2][1] - last_week[1] - initial[1]]

      {}.tap do |metrics|
        metrics[:views] = {:n => this_week[0]}
        metrics[:actions] = {:n => this_week[1]}
        metrics[:conversion] = {:n => this_week[0] == 0 ? 0 : (this_week[1].to_f / this_week[0]).round(4)}

        if data.count >= 15 # only calculate lift if we have two full weeks of data
          old_conversion = last_week[0] == 0 ? 0 : last_week[1].to_f / last_week[0]

          metrics[:views][:lift] = last_week[0] == 0 ? nil : (metrics[:views][:n] - last_week[0]) / last_week[0].to_f
          metrics[:actions][:lift] = last_week[1] == 0 ? nil : (metrics[:actions][:n] - last_week[1]) / last_week[1].to_f
          metrics[:conversion][:lift] = old_conversion == 0 ? nil : ((metrics[:conversion][:n] - old_conversion) / old_conversion.to_f).round(4)
        end
      end
    end

    def create_bar_cta(site, metrics, url)
      site_elements = site.site_elements.reload

      if metrics[:social].nil?
        "Use different types of bars to help you reach other goals, like gaining followers on Twitter. <a href='#{url}'>Start testing social bars now</a>."
      elsif metrics[:traffic].nil?
        "Use different types of bars to help you reach other goals, like driving traffic to important pages. <a href='#{url}'>Start testing traffic bars now</a>."
      elsif metrics[:email].nil?
        "Use different types of bars to help you reach other goals, like collecting email addresses. <a href='#{url}'>Start testing email bars now</a>."
      else
        element_subtypes = {:social => /^social/, :email => /^email/, :traffic => /^traffic/}
        worst_type = element_subtypes.keys.sort_by{|a| metrics[a][:conversion][:n]}.first
        worst_bars = site_elements.select{|b| b.element_subtype =~ element_subtypes[worst_type]}
        conversion_noun = site_element_activity_units(worst_bars, :plural => true)

        "Your #{worst_type} bars have the lowest conversion rate. Try creating a variation on your existing #{worst_type} bars to see if you can get more #{conversion_noun}. <a href='#{url}'>Start testing more #{worst_type} bars now</a>."
      end
    end

    def installed_params(site, user, metrics, email_name)
      create_bar_url = new_site_site_element_url(:site_id => site, :host => "www.hellobar.com", :trk => Hello::TrackingParam.encode_tracker(user.id, "click", "#{email_name}_create_bar_cta"))
      create_bar_button_url = new_site_site_element_url(:site_id => site, :host => "www.hellobar.com", :trk => Hello::TrackingParam.encode_tracker(user.id, "click", "#{email_name}_create_bar_button"))
      unsubscribe_url = edit_site_url(site, :host => "www.hellobar.com", :trk => Hello::TrackingParam.encode_tracker(user.id, "click", "#{email_name}_unsubscribe"))

      params = {
        :site_url => display_name_for_site(site),
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
        params[:total_views_lift] = formatted_percent_with_wrapper(nil)
        params[:total_actions_lift] = formatted_percent_with_wrapper(nil)
        params[:total_conversion_lift] = formatted_percent_with_wrapper(nil)
      else
        params[:total_views] = number_with_delimiter(metrics[:total][:views][:n])
        params[:total_actions] = number_with_delimiter(metrics[:total][:actions][:n])
        params[:total_conversion] = number_to_percentage(metrics[:total][:conversion][:n] * 100, :precision => 2)
        params[:total_views_lift] = formatted_percent_with_wrapper(metrics[:total][:views][:lift])
        params[:total_actions_lift] = formatted_percent_with_wrapper(metrics[:total][:actions][:lift])
        params[:total_conversion_lift] = formatted_percent_with_wrapper(metrics[:total][:conversion][:lift])
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
          params["#{bar_type}_views".to_sym] = "<big>#{number_with_delimiter(bar_data[:views][:n])}</big> <small>#{formatted_percent_with_wrapper(bar_data[:views][:lift], :parens => true)}</small>"
          params["#{bar_type}_actions".to_sym] = "<big>#{number_with_delimiter(bar_data[:actions][:n])}</big> <small>#{formatted_percent_with_wrapper(bar_data[:actions][:lift], :parens => true)}</small>"
          params["#{bar_type}_conversion".to_sym] = "<big>#{number_to_percentage(bar_data[:conversion][:n] * 100, :precision => 2)}</big> <small>#{formatted_percent_with_wrapper(bar_data[:conversion][:lift], :parens => true)}</small>"
        end
      end

      # Grand Central only accepts string parameters
      params.each{|k,v| params[k] = v.to_s}

      return params
    end

    def not_installed_params(site, user, email_name)
      unsubscribe_url = edit_site_url(site, :host => "www.hellobar.com", :trk => Hello::TrackingParam.encode_tracker(user.id, "click", "#{email_name}_unsubscribe"))
      install_url = site_url(site, :host => "www.hellobar.com", :trk => Hello::TrackingParam.encode_tracker(user.id, "click", "#{email_name}_install"))

      params = {
        :site_url => display_name_for_site(site),
        :tracking_pixel => tracking_pixel_url(:host => "www.hellobar.com", :trk => Hello::TrackingParam.encode_tracker(user.id, "open", email_name)),
        :unsubscribe_url => unsubscribe_url,
        :install_url => install_url
      }

      # Grand Central only accepts string parameters
      params.each{|k,v| params[k] = v.to_s}

      return params
    end
  end
end
