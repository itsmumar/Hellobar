class DynamoDB
  DEFAULT_TTL = 1.hour
  CACHE_KEY_PREFIX = 'DynamoDB'.freeze

  def initialize(cache_key:, expires_in: DEFAULT_TTL)
    @cache_key = cache_key
    @expires_in = expires_in
  end

  def fetch(request)
    self.last_request = request
    cache { query(request) }
  end

  def batch_fetch(request)
    self.last_request = request
    cache { batch_query(request) }
  end

  private

  attr_reader :expires_in
  attr_accessor :last_request

  def cache
    Rails.cache.fetch cache_key, expires_in: expires_in do
      yield
    end
  end

  def cache_key
    [CACHE_KEY_PREFIX, @cache_key].join('/')
  end

  def batch_query(request)
    rescue_from_service_error { client.batch_get_item(request).responses } || {}
  end

  def query(request)
    rescue_from_service_error { client.query(request).items } || []
  end

  def rescue_from_service_error
    yield
  rescue Aws::DynamoDB::Errors::ServiceError => e
    raise if Rails.env.development? || Rails.env.test?
    Raven.capture_exception(e, context: { request: last_request })
    nil
  end

  def client
    Aws::DynamoDB::Client.new
  end
end
