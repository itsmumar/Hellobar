class InternalMetricsMailer < ApplicationMailer
  RECIPIENTS = %w[
    neil@neilpatel.com
    mike@mikekamo.com
    mailmanager@hellobar.com
    swzrainey@gmail.com
    lindsey@hellobar.com
  ].freeze

  DEV_RECIPIENTS = %w[dev@hellobar.com].freeze

  include ActionView::Helpers::NumberHelper

  def summary
    @metrics = CalculateInternalMetrics.new.call

    mail to: to, subject: subject
  end

  private

  def to
    return DEV_RECIPIENTS unless Rails.env.production?

    RECIPIENTS
  end

  def subject
    "#{ @metrics.beginning_of_current_week } | #{ number_with_delimiter(@metrics.sites.size) } new sites, " \
    "#{ number_to_percentage((@metrics.installed_sites.size.to_f / @metrics.sites.size) * 100, precision: 2) } " \
    "install rate, #{ number_to_currency(@metrics.revenue_sum) } new revenue"
  end
end
