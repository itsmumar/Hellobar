RSpec::Matchers.define :make_gateway_call do |method_to_be_called|
  supports_block_expectations

  match(notify_expectation_failures: true) do |given_block|
    @response ||= {}

    allow_gateway_call

    matcher =
      if @args
        have_received(method_to_be_called).with(*@args).once
      else
        have_received(method_to_be_called).once
      end

    given_block.call

    expect(gateway).to matcher
  end

  match_when_negated do |given_block|
    allow_gateway_call

    given_block.call

    if @args
      expect(gateway).not_to have_received(method_to_be_called).with(*@args)
    else
      expect(gateway).not_to have_received(method_to_be_called)
    end
  end

  chain :with do |*args|
    @args = args
  end

  chain :and_fail do
    @fail = true
  end

  chain :and_succeed do
    @fail = false
  end

  chain :and_raise_error do |error|
    @error = error
  end

  chain :with_response do |response|
    @response = response
  end

  define_method :gateway do
    @gateway ||= double('CyberSourceGateway')
  end

  define_method :allow_gateway_call do
    allow(CyberSourceGateway).to receive(:new).and_return(gateway)

    matcher =
      if @fail
        receive(method_to_be_called).and_return(double(success?: false, message: 'gateway error', **(@response || {})))
      elsif @error
        receive(method_to_be_called).and_raise @error
      else
        receive(method_to_be_called).and_return(double(success?: true, authorization: 'authorization', **(@response || {})))
      end

    allow(gateway).to matcher
  end

  failure_message do
    "expected that gateway had received #{ expected }"
  end

  failure_message_when_negated do
    "expected that gateway had not received #{ expected }"
  end

  description do
    args = (@args || []).map { |arg| arg.respond_to?(:description) ? arg.description : arg }.join(', ')
    args = args.present? ? "(#{ args })" : ''
    "call gateway.#{ method_to_be_called }#{ args }"
  end
end
