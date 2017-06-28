RSpec::Matchers.define :be_capable_of do |plan|
  match do |site|
    @capabilities = site.capabilities
    expect(@capabilities).to be_an_instance_of capabilities_klass
  end

  match_when_negated do |given_block|
  end

  define_method :capabilities_klass do
    Subscription.const_get(plan.to_s.classify).const_get(:Capabilities)
  end

  failure_message do
    "expected that site.capabilities (#{ @capabilities.class }) is an instance of #{ capabilities_klass }"
  end

  failure_message_when_negated do
    "expected that site.capabilities (#{ @capabilities.class }) is not an instance of #{ capabilities_klass }"
  end

  description do
    "site.capabilities is an instance of #{ capabilities_klass }"
  end
end
