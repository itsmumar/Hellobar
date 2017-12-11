class InternalMetricsMailer < ApplicationMailer
  include ActionView::Helpers::NumberHelper

  def summary
    @metrics = CalculateInternalMetrics.new.call

    mail to: to, subject: subject
  end

  private

  def to
    return %w[dev@hellobar.com] unless Rails.env.production?

    %w[
      neil@neilpatel.com
      mike@mikekamo.com
      mailmanager@hellobar.com
      swzrainey@gmail.com
      lindsey@hellobar.com
    ]
  end

  def subject
    "#{ @metrics.last_week } | #{ number_with_delimiter(@metrics.sites.size) } new sites, " \
    "#{ number_to_percentage((@metrics.installed_sites.size.to_f / @metrics.sites.size) * 100, precision: 1) } " \
    "install rate, #{ number_to_currency(@metrics.revenue_sum) } new revenue"
  end
end
