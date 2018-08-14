RSpec::Matchers.define :receive_service_call do
  include RSpec::Mocks::Matchers::Matcher

  match do |service_class|
    @service_name = service_class.name
    @service_double = double service_class.name
    @times ||= 1

    if @args
      expect(service_class).to receive(:new).with(*@args).exactly(@times).times.and_return(@service_double)
    else
      expect(service_class).to receive(:new).exactly(@times).times.and_return(@service_double)
    end

    if @return_value
      expect(@service_double).to receive(:call).exactly(@times).times.and_return(@return_value)
    elsif @error
      expect(@service_double).to receive(:call).exactly(@times).times.and_raise(@error)
    else
      expect(@service_double).to receive(:call).exactly(@times).times
    end
  end

  match_when_negated do |service_class|
    @service_name = service_class.name
    @service_double = double service_class.name

    if @args
      expect(service_class).not_to receive(:new).with(*@args)
    else
      expect(service_class).not_to receive(:new)
    end
  end

  def setup_allowance(subject)
    if @return_value
      allow(subject).to receive_message_chain(:new, :call).and_return(@return_value)
    else
      allow(subject).to receive_message_chain(:new, :call)
    end
  end

  chain :with do |*args|
    @args = args
  end

  chain :and_return do |return_value|
    @return_value = return_value
  end

  chain :and_raise do |error|
    @error = error
  end

  chain :exactly do |times|
    @times = times
  end

  chain :times do
  end

  description do
    @service_name.underscore.humanize.downcase
  end
end
