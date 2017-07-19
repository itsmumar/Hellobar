class DynamoDB
  def initialize(cache_key:, expires_in: 1.hour)
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

  def scan(request)
    self.last_request = request
    cache { scan_all(request) }
  end

  private

  attr_reader :cache_key, :expires_in
  attr_accessor :last_request

  def cache
    Rails.cache.fetch cache_key, expires_in: expires_in do
      yield
    end
  end

  def batch_query(request)
    rescue_from_service_error { client.batch_get_item(request).responses } || {}
  end

  def query(request)
    rescue_from_service_error { client.query(request).items } || []
  end

  def scan_all(request)
    rescue_from_service_error { client.scan(request).items } || []
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
