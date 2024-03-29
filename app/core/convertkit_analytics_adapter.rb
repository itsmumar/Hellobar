class ConvertkitAnalyticsAdapter
  include HTTParty

  def track(event:, user:, params:)
    return if event.blank?
    tag = create_or_find_tag(event)
    user = tag_subscriber(tag, user, params || {})
    verify_subscription_tag(event, tag, user, params)
  end

  # rubocop:disable Lint/UnneededDisable
  # rubocop:disable Lint/UnusedMethodArgument

  def untag_users(tag, users)
    # TODO: Implement UnTag
  end

  def update_user(user:, params: {})
    # TODO: Implement update user
  end

  # rubocop:enable Lint/UnusedMethodArgument, Lint/UnneededDisable
  def tag_users(tag, users)
    return if users.blank? || tag.blank?
    ctag = create_or_find_tag(tag)
    users.each do |user|
      tag_subscriber(ctag, user, {}) # TODO: Implement API End point to tag multiple users in one all
    end
  end

  private

  def list_tag
    self.class.get base_uri('tags')
  end

  def list_subscribers
    self.class.get base_uri('subscribers')
  end

  def create_tag(tag_name)
    self.class.post base_uri('tags'), body: {
      api_key: Settings.convertkit_api_keys,
      tag: { "name": tag_name }
    }
  end

  def remove_tag(tag, user)
    self.class.post base_uri("tags/#{ tag['id'] }/unsubscribe"), body: { api_key: Settings. convertkit_api_keys, email: user.email }
  end

  def create_or_find_tag(event)
    tag = create_tag(event)
    return tag if tag['error'].blank?
    find_tag(event)
  end

  def find_tag(event)
    tags = list_tag
    tags['tags'].find do |t|
      return t if t['name'] == event
    end
  end

  def tag_subscriber(tag, user, params)
    response = self.class.post base_uri("tags/#{ tag['id'] }/subscribe"), body: { api_key: Settings.convertkit_api_keys,
                                                                       email: user.email,
                                                                       first_name: user.first_name.to_s,
                                                                       fields: params }
    user.update_column(:convortkit_subscriber_id, response['subscription']['subscriber']['id']) if user.convortkit_subscriber_id.blank?
    user
  end

  def verify_subscription_tag(event, _tag, user, _params)
    case event
    when 'installed-script'
      r_tag = find_tag('uninstalled-script')
    when 'uninstalled-script'
      r_tag = find_tag('installed-script')
    when 'created-popup'
      r_tag = find_tag('not-yet-created-popup')
    when 'inactive'
      r_tag = find_tag('active')
    when 'active'
      r_tag = find_tag('inactive')
    when 'ab-test-created'
      r_tag = find_tag('no-ab-test')
    end
    remove_tag(r_tag, user) if r_tag.present?
  end

  def base_uri(endpoint)
    "https://api.convertkit.com/v3/#{ endpoint }?api_secret=#{ Settings.convertkit_api_secret }"
  end
end
