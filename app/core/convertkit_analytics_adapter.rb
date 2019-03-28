class ConvertkitAnalyticsAdapter
  include HTTParty

  def track(event:, user:, params:)
    tag = create_or_find_tag(event)
    tag_subscriber(tag, user, params || {})
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

  def create_or_find_tag(event)
    tag = create_tag(event)
    return tag if tag['error'].blank?
    tags = list_tag
    tags['tags'].find do |t|
      return t if t['name'] == event
    end
  end

  def tag_subscriber(tag, user, params)
    self.class.post base_uri("tags/#{ tag['id'] }/subscribe"), body: {
      api_key: Settings.convertkit_api_keys,
      email: user.email,
      first_name: user.first_name.to_s,
      fields: params
    }
  end

  def base_uri(endpoint)
    "https://api.convertkit.com/v3/#{ endpoint }?api_secret=#{ Settings.convertkit_api_secret }"
  end
end
