class InternalReport < ActiveRecord::Base
  serialize :data, JSON

  class << self
    def clear
      destroy_all
    end

    def set(name, data)
      report = InternalReport.where(name: name).first || InternalReport.new
      report.name = name
      report.data = data
      report.save!
    end

    def get(name)
      InternalReport.where(name: name).first
    end

    def get_data(name)
      report = InternalReport.get(name)
      return nil unless report
      begin
        report.try :data
      rescue NoMethodError
        nil
      end
    end

    def generate_all
      generate_top_referrer_metrics
      generate_over_time_metrics
      generate_optimizely_metrics
      generate_installed_email_digest_metrics
      generate_not_installed_email_digest_metrics
    end

    def generate_top_referrer_metrics
      set("referrer", generate_kpis_via_dimension("referrer"))
    end

    def generate_over_time_metrics
      now = Time.now
      set("over_time_by_day", generate_kpis_via_date_range(now-7.days, now, "%Y-%m-%d", 1.day))
      set("over_time_by_week", generate_kpis_via_date_range(now-1.year, now, "Week of %Y.%m.%d", 7.days))
    end

    def generate_optimizely_metrics
      experiments = InternalProp.where("name like 'Optimizely: %'").select("DISTINCT(NAME)").map{|p| p["NAME"]}

      experiments.each do |experiment|
        set(experiment, generate_kpis_via_dimension(experiment))
      end
    end

    def generate_installed_email_digest_metrics
      variations = (1..8).map{|w| "installed_v1_w#{w}"}
      links = %w(create_bar_cta create_bar_button unsubscribe)
      generate_email_digest_metrics("installed_email_digest", variations, links)
    end

    def generate_not_installed_email_digest_metrics
      variations = (1..4).map{|w| "not_installed_v1_w#{w}"}
      links = %w(install unsubscribe)
      generate_email_digest_metrics("not_installed_email_digest", variations, links)
    end

    def generate_email_digest_metrics(name, variations, links)
      metrics = {}

      variations.map(&:to_sym).each do |variation|
        metrics[variation] = {
          "total" => InternalProp.where(:name => variation).count,
          "opens" => InternalEvent.where(:name => "Opened email: #{variation}").select(:target_id).uniq.count
        }

        links.each do |link|
          metrics[variation]["Clicked link: #{link}"] = InternalEvent.where(:name => "Clicked link: #{variation}_#{link}").select(:target_id).uniq.count
        end
      end

      set(name, metrics)
    end

    def generate_kpis_via_dimension(dimension, options={})
      cxn = ActiveRecord::Base.connection
      sql = %{SELECT
        #{internal_people_select},
        internal_dimensions.value
      FROM internal_people, internal_dimensions
      WHERE
        internal_dimensions.name = #{cxn.quote(dimension)} AND
        internal_people.id = internal_dimensions.person_id
      }
      generate_kpis_from_sql(sql, options)
    end

    def generate_kpis_via_date_range(start_date, end_date, date_format, date_unit, options={})
      sql = %{SELECT
        #{internal_people_select},
        DATE_FORMAT(FROM_UNIXTIME(FLOOR(IFNULL(internal_people.first_visited_at, internal_people.signed_up_at)/#{date_unit})*#{date_unit}), '#{date_format}')

      FROM internal_people
      WHERE
        IFNULL(internal_people.first_visited_at, internal_people.signed_up_at) >= #{start_date.to_i} AND
        IFNULL(internal_people.first_visited_at, internal_people.signed_up_at) <= #{end_date.to_i}
      }
      generate_kpis_from_sql(sql, options)
    end

    def internal_people_select
      %{internal_people.signed_up_at,
        internal_people.completed_registration_at,
        internal_people.created_first_bar_at,
        internal_people.created_second_bar_at,
        internal_people.received_data_at}
    end

    def generate_kpis_from_sql(sql, options={})
      results = Hash.new{|h,k| h[k] = {total: 0, signed_up: 0, completed_registration: 0, created_first_bar: 0, created_second_bar: 0, installed: 0, total_time_first_bar: 0}}
      dimension_lookups = nil
      if options[:dimension_lookups]
        dimension_lookups = {}
        options[:dimension_lookups].each do |value, keys|
          keys.each do |key|
            dimension_lookups[key] = value
          end
        end
      end
      
      ActiveRecord::Base.connection.execute(sql).each do |row|
        signed_up_at, completed_registration_at, created_first_bar_at, created_second_bar_at, received_data_at, value = *row
        key = value
        if dimension_lookups
          key = dimension_lookups[key] || dimension_lookups[:*] || key
        end
        result = results[key]
        result[:total] += 1
        result[:signed_up] += 1 if signed_up_at
        result[:completed_registration] += 1 if completed_registration_at
        result[:created_first_bar] += 1 if created_first_bar_at
        result[:created_second_bar] += 1 if created_second_bar_at
        result[:installed] += 1 if received_data_at
        result[:total_time_first_bar] += (created_first_bar_at-signed_up_at) if created_first_bar_at and signed_up_at and created_first_bar_at-signed_up_at < 30*60
      end
      return results
    end
  end
end
