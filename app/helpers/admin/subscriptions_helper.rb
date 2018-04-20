module Admin::SubscriptionsHelper
  def subscription_owner_link(subscription)
    return unless subscription.site

    owner = subscription.site.owners.first

    return unless owner

    link_to(owner.email, admin_user_path(owner))
  end

  def subscription_filters
    filters = [
      ['All', admin_subscriptions_path]
    ]

    Subscription::ALL.each do |subscription_class|
      filters << [
        subscription_class.defaults[:name],
        filter_by_type_admin_subscriptions_path(type: subscription_class.to_s.demodulize.underscore)
      ]
    end

    filters << ['Ended trial', ended_trial_admin_subscriptions_path]

    items = filters.map do |title, path|
      css = [:presentation]
      css << :active if current_page?(path)
      content_tag :li, class: css do
        link_to title, path
      end
    end

    content_tag :ul, class: %w[nav nav-tabs] do
      safe_join(items)
    end
  end
end
