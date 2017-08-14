class DiamondAnalytics
  def fire_event(event, **args)
    public_send(event.underscore.to_sym, **args)
  end

  def signed_up(user:)
    track(
      event: 'Signed Up',
      identities: {
        user_id: user.id,
        user_email: user.email
      },
      timestamp: user.created_at.to_f
    )
  end

  def invited_member(site:, user:)
    track(
      event: 'Invited Member',
      identities: {
        site_id: site.id,
        user_id: user.id,
        user_email: user.email
      },
      timestamp: user.created_at.to_f,
      properties: {
        site_url: site.url
      }
    )
  end

  def created_site(site:, user:)
    track(
      event: 'Created Site',
      identities: {
        site_id: site.id,
        user_id: user.id,
        user_email: user.email
      },
      timestamp: site.created_at.to_f,
      properties: {
        site_url: site.url
      }
    )
  end

  def created_contact_list(contact_list:, user:)
    track(
      event: 'Created Contact List',
      identities: {
        site_id: contact_list.site_id,
        user_id: user.id,
        user_email: user.email
      },
      timestamp: contact_list.created_at.to_f,
      properties: {
        site_url: contact_list.site.url
      }
    )
  end

  def created_bar(site_element:, user:)
    track(
      event: 'Created Bar',
      identities: {
        site_id: site_element.site_id,
        user_id: user.id,
        user_email: user.email
      },
      timestamp: site_element.created_at.to_f,
      properties: {
        element_type: site_element.type,
        element_goal: site_element.element_subtype
      }
    )
  end

  def changed_subscription(site:, user:)
    subscription = site.current_subscription

    track(
      event: 'Changed Subscription',
      identities: {
        site_id: site.id,
        user_id: user.id,
        user_email: user.email
      },
      timestamp: subscription.created_at.to_f,
      properties: {
        subscription: subscription.name,
        subscription_schedule: subscription.schedule
      }
    )

    site.owners.each do |owner|
      track(
        identities: {
          user_id: owner.id,
          user_email: owner.email
        },
        timestamp: subscription.created_at.to_f,
        properties: {
          paid: subscription.amount.positive?,
          subscription: subscription.name
        }
      )
    end
  end

  def assigned_ab_test(visitor_id:, user:, test_name:, assignment:, timestamp:)
    identities = {
      visitor_id: visitor_id,
      user_id: user&.id,
      user_email: user&.email
    }.compact

    return if identities.blank?

    track(
      event: 'A/B Assignment',
      identities: identities,
      timestamp: timestamp.to_f,
      properties: {
        test_name: test_name,
        assignment: assignment
      }
    )
  end

  def identify(identities:, timestamp: nil)
    timestamp ||= Time.current

    track(
      identities: identities,
      timestamp: timestamp.to_f
    )
  end

  private

  def track(args)
    diamond.track(args) if enabled?
  end

  def enabled?
    Settings.diamond_endpoint.present?
  end

  def diamond
    @diamond ||= Diamond::Client.new(endpoint: Settings.diamond_endpoint)
  end
end
