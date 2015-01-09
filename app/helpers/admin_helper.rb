module AdminHelper
  def metric_time(seconds)
    return "" unless seconds
    seconds = seconds.to_i
    minutes = seconds/60
    seconds -= minutes*60
    return "#{minutes}:#{"%02d" % seconds}"
  end

  def metric_percent(numerator, denominator)
    percent = 0
    if denominator > 0
      percent = 100*(numerator.to_f/denominator)
    end
    %{<span class="data">#{numerator}</span> <span class="percent">(#{"%0.2f" % percent}%)</span>}
  end

  def last_updated_report(report)
    date = [report.updated_at, report.created_at].compact.max
    return "updated #{distance_of_time_in_words_to_now(date)} (#{date})"
  end

  def render_report(test_name, options={}, col1, col2)
    options = {title: "", subtitle: ""}.merge(options)
    return ""
    options[:subtitle] += " - "+last_updated_report(report)
    headline = %{<h3>#{options[:title]} <small>#{options[:subtitle]}</small></h3>}
    html = ""
    table_id = test_name.gsub(/\W/, "_").downcase
    html << headline
    html << %{<table class="admin-metrics table" id="#{table_id}">}
    html << yield(report.data)
    html << "</table>"
    html << %{<p class="admin-table-summary" id="#{table_id}-summary"></p>}
    html << %{<script>registerTestResults(#{table_id.inspect}, "#{col1}", "#{col2}")</script>}
    return html.html_safe
  end

  def render_email_drip_kpis(test_name, options = {})
    kpis = [:total] + (options[:kpis] || [])

    render_report(test_name, options, kpis.first, kpis.last) do |metrics|
      links = metrics.first[1].keys.select{|k| k =~ /Clicked link/}.map{|k| k.gsub("Clicked link: ", "")} rescue []
      link_headers = links.map{|l| "<th data-col='#{l.downcase.gsub(" ", "_")}'>Clicked \"#{l.gsub(/drip \d /i, "")}\"</th>"}

      kpi_headers = (kpis - [:total]).map{|k| "<th data-col='#{k}'>#{k.to_s.humanize}</th>"}

      html = ""
      html << %{
          <tr class="header">
            <th data-col="key" data-ignore="true">&nbsp;</th>
            <th data-col="total">Users</th>
            <th data-col="opens">Opens</th>
            #{link_headers.join("\n")}
            #{kpi_headers.join("\n")}
          </tr>
      }

      metrics_as_list = metrics.collect{|key, data| data["key"] = key; data}
      sort_by = options[:sort_by] || "key"
      limit = options[:limit] || 20
      metrics_as_list.sort!{|a,b| b[sort_by] <=> a[sort_by]}

      metrics_as_list[0..limit].each do |data|
        link_rows = links.map{|l| "<td>#{metric_percent(data["Clicked link: " + l], data["total"])}</td>"}
        kpi_rows = (kpis - [:total]).map{|k| "<td>#{metric_percent(data[k.to_s], data["total"])}</td>"}

        html << %{<tr data-row="#{data["key"]}">
          <th>#{data["key"]}</th>
          <td>#{data["total"]}</td>
          <td>#{data["opens"]}</td>
          #{link_rows.join("\n")}
          #{kpi_rows.join("\n")}
        </tr>}
      end

      html
    end
  end

  def render_email_digest_kpis(name, options = {})
    render_report(name, options, "total", "opens") do |metrics|
      puts metrics.inspect
      links = metrics.first[1].keys.select{|k| k =~ /Clicked link/}.map{|k| k.gsub("Clicked link: ", "")} rescue []
      link_headers = links.map{|l| "<th data-col='#{l.downcase.gsub(" ", "_")}'>Clicked \"#{l.gsub(/drip \d /i, "")}\"</th>"}

      html = ""
      html << %{
          <tr class="header">
            <th data-col="key" data-ignore="true">&nbsp;</th>
            <th data-col="total">Sends</th>
            <th data-col="opens">Opens</th>
            #{link_headers.join("\n")}
          </tr>
      }

      metrics_as_list = metrics.collect{|key, data| data["key"] = key; data}
      metrics_as_list.sort!{|a,b| a["key"] <=> b["key"]}

      metrics_as_list.each do |data|
        link_rows = links.map{|l| "<td>#{metric_percent(data["Clicked link: " + l], data["total"])}</td>"}

        html << %{<tr data-row="#{data["key"]}">
          <th>#{data["key"]}</th>
          <td>#{data["total"]}</td>
          <td>#{data["opens"]}</td>
          #{link_rows.join("\n")}
        </tr>}
      end

      html
    end
  end

  def render_bar_suggestion_kpis(test_name, options={})
    render_report(test_name, options, :total, :created_second_bar) do |metrics|
      html = ""
      html << %{
          <tr class="header">
            <th data-col="key" data-ignore="true">&nbsp;</th>
            <th data-col="total">Users</th>
            <th data-col="created_first_bar">First Bar</th>
            <th data-col="created_second_bar">Second Bar</th>
          </tr>
      }
      metrics_as_list = metrics.collect{|key, data| data["key"] = key; data}
      sort_by = options[:sort_by] || "key"
      limit = options[:limit] || 20
      metrics_as_list.sort!{|a,b| b[sort_by] <=> a[sort_by]}

      metrics_as_list[0..limit].each do |data|
        html << %{<tr data-row="#{data["key"]}">
          <th>#{data["key"]}</th>
          <td>#{data["total"]}</td>
          <td>#{metric_percent(data["created_first_bar"], data["total"])}</td>
          <td>#{metric_percent(data["created_second_bar"], data["total"])}</td>
        </tr>} 
      end
      html
    end
  end

  def render_post_signup_kpis(test_name, options={})
    render_report(test_name, options, :signed_up, :installed) do |metrics, headline|
      html = ""
      html << %{
          <tr class="header">
            <th data-col="key" data-ignore="true">&nbsp;</th>
            <th data-col="signed_up">Signups</th>
            <th data-col="completed_registration">Registered</th>
            <th data-col="created_first_bar">First Bar</th>
            <th data-col="installed">Installed</th>
            <th data-col="created_second_bar">Second Bar</th>
            <th data-col="avg_time_first_bar" data-ignore="true">First Bar Time</th>
          </tr>
      }
      metrics_as_list = metrics.collect{|key, data| data["key"] = key; data}
      sort_by = options[:sort_by] || "key"
      limit = options[:limit] || 20
      metrics_as_list.sort!{|a,b| b[sort_by] <=> a[sort_by]}

      metrics_as_list[0..limit].each do |data|
        avg_time_first_bar = nil
        if data["total_time_first_bar"] and data["total_time_first_bar"] > 0 and data["created_first_bar"] and data["created_first_bar"] > 0
          avg_time_first_bar = data["total_time_first_bar"]/data["created_first_bar"]
        end
        html << %{<tr data-row="#{data["key"]}">
          <th>#{data["key"]}</th>
          <td>#{data["signed_up"]}</td>
          <td>#{metric_percent(data["completed_registration"], data["signed_up"])}</td>
          <td>#{metric_percent(data["created_first_bar"], data["signed_up"])}</td>
          <td>#{metric_percent(data["installed"], data["signed_up"])}</td>
          <td>#{metric_percent(data["created_second_bar"], data["signed_up"])}</td>
          <td>#{metric_time(avg_time_first_bar)}</td>
        </tr>} 
      end
      html
    end
  end

  def render_signup_kpis(test_name, options={})
    render_report(test_name, options, :total, :installed) do |metrics|
      html = ""
      html << %{
          <tr class="header">
            <th data-col="key" data-ignore="true">&nbsp;</th>
            <th data-col="total">Visitors</th>
            <th data-col="signed_up">Signups</th>
            <th data-col="completed_registration">Registered</th>
            <th data-col="created_first_bar">First Bar</th>
            <th data-col="installed">Installed</th>
            <th data-col="created_second_bar">Second Bar</th>
            <th data-col="avg_time_first_bar" data-ignore="true">First Bar Time</th>
          </tr>
      }
      metrics_as_list = metrics.collect{|key, data| data["key"] = key; data}
      sort_by = options[:sort_by] || "key"
      limit = options[:limit] || 20
      metrics_as_list.sort!{|a,b| b[sort_by] <=> a[sort_by]}

      metrics_as_list[0..limit].each do |data|
        avg_time_first_bar = nil
        if data["total_time_first_bar"] and data["total_time_first_bar"] > 0 and data["created_first_bar"] and data["created_first_bar"] > 0
          avg_time_first_bar = data["total_time_first_bar"]/data["created_first_bar"]
        end
        html << %{<tr data-row="#{data["key"]}">
          <th>#{data["key"]}</th>
          <td>#{data["total"]}</td>
          <td>#{metric_percent(data["signed_up"], data["total"])}</td>
          <td>#{metric_percent(data["completed_registration"], data["total"])}</td>
          <td>#{metric_percent(data["created_first_bar"], data["total"])}</td>
          <td>#{metric_percent(data["installed"], data["total"])}</td>
          <td>#{metric_percent(data["created_second_bar"], data["total"])}</td>
          <td>#{metric_time(avg_time_first_bar)}</td>
        </tr>} 
      end
      html
    end
  end

  def render_bar_data(test_name, options={})
    render_report(test_name, options, :total, :social_bars) do |metrics, headline|
      html = ""
      html << %{
          <tr class="header">
            <th data-col="key" data-ignore="true">&nbsp;</th>
            <th data-col="total">Total</th>
            <th data-col="link_bars">Link Bars</th>
            <th data-col="email_bars">Email Bars</th>
            <th data-col="social_bars">Social Bars</th>
          </tr>
      }
      metrics_as_list = metrics.collect{|key, data| data["key"] = key; data}
      sort_by = options[:sort_by] || "key"
      limit = options[:limit] || 20
      metrics_as_list.sort!{|a,b| b[sort_by] <=> a[sort_by]}

      metrics_as_list[0..limit].each do |data|
        html << %{<tr data-row="#{data["key"]}">
          <th>#{data["key"]}</th>
          <td>#{data["total"]}</td>
          <td>#{metric_percent(data["Goals::DirectTraffic"], data["total"])}</td>
          <td>#{metric_percent(data["Goals::CollectEmail"], data["total"])}</td>
          <td>#{metric_percent(data["Goals::SocialMedia"], data["total"])}</td>
        </tr>} 
      end
      html
    end
  end
end
