class DynamoDB
  DEFAULT_TTL = 1.hour
  CACHE_KEY_PREFIX = 'DynamoDB'.freeze

  attr_accessor :last_request, :last_response
  attr_reader :expires_in

  def initialize(cache_key: nil, expires_in: DEFAULT_TTL)
    @cache_key = cache_key
    @expires_in = expires_in
  end

  def query(request)
    cache { send_query(request) }
  end

  def batch_get_item(request)
    cache { send_batch_get_item(request) }
  end

  def update_item params
    response = send_request :update_item, params
    response || {}
  end

  private

  def cache
    return yield unless cache_key

    Rails.cache.fetch cache_key, expires_in: expires_in do
      yield
    end
  end

  def cache_key
    return unless @cache_key
    [CACHE_KEY_PREFIX, @cache_key].join('/')
  end

  def send_batch_get_item(request)
    response = send_request(:batch_get_item, request)
    response&.responses || {}
  end

  def send_query(request)
    response = send_request(:query, request)
    response&.items || []
  end

  def send_request(method, request)
    self.last_request = [method, request]
    rescue_from_service_error do
      self.last_response = client.send(method, request)
    end
    last_response
  end

  def instrument
    ActiveSupport::Notifications.instrument('query.dynamo_db', {}) do |payload|
      response = yield
      payload[:method], payload[:request] = last_request
      payload[:consumed_capacity] = response.consumed_capacity
      response
    end
  end

  def rescue_from_service_error
    instrument { yield }
  rescue Aws::DynamoDB::Errors::ServiceError => e
    raise if Rails.env.development? || Rails.env.test?
    Raven.capture_exception(e, context: { request: last_request })
    nil
  end

  def client
    Aws::DynamoDB::Client.new
  end
end

DynamoDB::LogSubscriber.attach_to :dynamo_db
