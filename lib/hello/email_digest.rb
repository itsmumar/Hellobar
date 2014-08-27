module Hello::EmailDigest
  class << self
    include Hellobar::Application.routes.url_helpers
    include EmailDigestHelper
    include SiteElementsHelper

    def installed_sites
      Site.where("script_installed_at IS NOT NULL").select{|s| s.send_email_digest?}
    end

    def not_installed_sites
      Site.where(:script_installed_at => nil).where("created_at > ?", 4.weeks.ago).select{|s| s.send_email_digest?}
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
      api_data = Hello::DataAPI.lifetime_totals(site, site.site_elements, 14)
      site_element_data = []
      metrics = {}

      api_data.keys.each do |site_element_id|
        site_element = SiteElement.find(site_element_id)

        api_data[site_element_id].each_with_index do |datum, i|
          site_element_data << OpenStruct.new(
            :site_element_id => site_element.id,
            :conversions => datum[1],
            :views => datum[0],
            :days_ago => api_data[site_element_id].count - i - 1,
            :subtype => site_element.element_subtype
          )
        end
      end

      {:social => /^social/, :email => /^email/, :traffic => /^traffic/, :total => /./}.each do |key, element_subtype_pattern|
        element_subtype_data = site_element_data.select{ |d| d.subtype =~ element_subtype_pattern }
        metrics[key] = site_element_metrics_for_site(site, element_subtype_data)
      end

      return metrics
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

    def site_element_metrics_for_site(site, site_element_data)
      return nil if site_element_data.empty?

      this_week, last_week = site_element_data.partition{ |d| d.days_ago < 7 }
      metrics = {}

      # calculate this week's metrics
      metrics[:views] = {:n => this_week.sum(&:views)}
      metrics[:actions] = {:n => this_week.sum(&:conversions)}
      metrics[:conversion] = {:n => this_week.sum(&:views) == 0 ? 0 : (this_week.sum(&:conversions).to_f / this_week.sum(&:views)).round(4)}

      # calculate lift over last week if we have sufficient data
      if last_week.any? && site.script_installed_at && site.script_installed_at <= 14.days.ago.beginning_of_day
        if last_week.sum(&:views) == 0
          metrics[:views][:lift] = nil
        else
          metrics[:views][:lift] = (metrics[:views][:n] - last_week.sum(&:views)) / last_week.sum(&:views).to_f
        end

        if last_week.sum(&:conversions) == 0
          metrics[:actions][:lift] = nil
        else
          metrics[:actions][:lift] = (metrics[:actions][:n] - last_week.sum(&:conversions)) / last_week.sum(&:conversions).to_f
        end

        if metrics[:conversion][:n].nil? || last_week.sum(&:views) == 0 || last_week.sum(&:conversions) == 0
          metrics[:conversion][:lift] = nil
        else
          conversion = (last_week.sum(&:conversions).to_f / last_week.sum(&:views)).round(4)
          metrics[:conversion][:lift] = ((metrics[:conversion][:n] - conversion) / conversion).round(4)
        end
      end

      return metrics
    end
  end
end
