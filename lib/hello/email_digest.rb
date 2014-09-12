module Hello::EmailDigest
  class << self
    include Hellobar::Application.routes.url_helpers
    include EmailDigestHelper
    include SiteElementsHelper

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
      InternalEvent.create(
        :timestamp => Time.now.to_i,
        :target_id => user.id,
        :target_type=>"user",
        :name => "Sent email digest: #{email_name}"
      )
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
      this_week = [data[-2][0] - last_week[0], data[-2][1] - last_week[1]]

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
      site_elements = site.site_elements

      if !site_elements.any?{|b| b.element_subtype =~ /^social/}
        "Use different types of bars to help you reach other goals, like gaining followers on Twitter. <a href='#{url}'>Start testing social bars now</a>."
      elsif !site_elements.any?{|b| b.element_subtype =~ /^traffic/}
        "Use different types of bars to help you reach other goals, like driving traffic to important pages. <a href='#{url}'>Start testing traffic bars now</a>."
      elsif !site_elements.any?{|b| b.element_subtype =~ /^email/}
        "Use different types of bars to help you reach other goals, like collecting email addresses. <a href='#{url}'>Start testing email bars now</a>."
      else
        element_subtypes = {:social => /^social/, :email => /^email/, :traffic => /^traffic/}
        worst_type = element_subtypes.keys.sort_by{|a| metrics[a][:conversion][:n]}.first
        worst_bars = site_elements.select{|b| b.element_subtype =~ element_subtypes[worst_type]}
        conversion_noun = site_element_activity_units(worst_bars, :plural => true)

        "Your #{worst_type} bars have the lowest conversion rate. Try creating a variation on your existing #{worst_type} bars to see if you can get more #{conversion_noun}. <a href='#{url}'>Start testing more #{worst_type} bars now</a>."
      end
    end
  end
end
