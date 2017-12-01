class DynamoDB
  DEFAULT_TTL = 1.hour
  CACHE_KEY_PREFIX = 'DynamoDB'.freeze

  attr_accessor :last_request, :last_response
  attr_reader :expires_in

  def self.contacts_table_name
    case Rails.env
    when 'staging'
      'staging_contacts'
    when 'production'
      'contacts'
    when 'edge'
      'edge_contacts'
    else # development / test
      'development_contacts'
    end
  end

  def self.visits_table_name
    case Rails.env
    when 'staging'
      'staging_over_time'
    when 'production'
      'over_time'
    else # edge / development / test
      'edge_over_time2'
    end
  end

  def initialize(expires_in: DEFAULT_TTL)
    @expires_in = expires_in
  end

  # Executes query and calls the block given with each item from the response.
  #
  # @param request [Hash] dynamo DB query (@see http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_Query.html)
  # @param fetch_all [Boolean] specifies whether all items should be fetched or just the first page (true by default).
  #
  # @yield [record] Gives fetched records to the block 1 by 1.
  # @yieldparam record [Hash] record fetches from DynamoDB.
  #
  def query_each(request, fetch_all: true, &block)
    pending_request = request.dup
    while pending_request
      response = cache(pending_request) { send_query(pending_request) }
      (response&.items || []).each(&block)

      pending_request = fetch_all &&
                        response&.last_evaluated_key &&
                        pending_request.merge(exclusive_start_key: response.last_evaluated_key)
    end
  end

  # Executes query and return an enumerator (@see #query_each for the list of arguments)
  def query_enum(*args)
    to_enum(:query_each, *args)
  end

  # Executes query and returns an array (@see #query_each for the list of arguments).
  def query(*args)
    query_enum(*args).to_a
  end

  def batch_get_item(request)
    cache(request) { send_batch_get_item(request) }
  end

  def update_item params
    response = send_request :update_item, params
    response || {}
  end

  private

  def cache(request)
    Rails.cache.fetch cache_key(request), expires_in: expires_in do
      yield
    end
  end

  def cache_key(request)
    [CACHE_KEY_PREFIX, Digest::MD5.hexdigest(request.inspect)].join('/')
  end

  def send_batch_get_item(request)
    response = send_request(:batch_get_item, request)
    response&.responses || {}
  end

  def send_query(request)
    send_request(:query, request)
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
