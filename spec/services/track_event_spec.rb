describe TrackEvent do
  before { allow(Rails.env).to receive(:production?).and_return true }
  let(:event) { :foo_bar_event }
  let(:params) { Hash[foo: 'foo', bar: 'bar'] }
  let(:service) { TrackEvent.new(event, **params) }

  it 'enqueues SendEventToIntercomJob' do
    service.call
    expect(SendEventToIntercomJob)
      .to have_been_enqueued
      .with(event.to_s, params)
  end

  it 'enqueues SendEventToAmplitudeJob' do
    service.call
    expect(SendEventToAmplitudeJob)
      .to have_been_enqueued
      .with(event.to_s, params)
  end

  context 'when event is :upgrade_account_triggered' do
    let(:event) { :upgrade_account_triggered }

    it 'enqueues SendEventToAmplitudeJob' do
      service.trigger
      expect(SendEventToAmplitudeJob)
        .to have_been_enqueued
        .with(event.to_s, params)
    end
  end

  context 'when event is :payment_checkout_triggered' do
    let(:event) { :payment_checkout_triggered }

    it 'enqueues SendEventToAmplitudeJob' do
      service.trigger
      expect(SendEventToAmplitudeJob)
        .to have_been_enqueued
        .with(event.to_s, params)
    end
  end

  context 'when event is :upgraded_subscription' do
    let(:event) { :upgraded_subscription }

    it 'enqueues SendEventToProfitwellJob' do
      service.call
      expect(SendEventToProfitwellJob)
        .to have_been_enqueued
        .with(event.to_s, params)
    end
  end

  context 'when event is :downgraded_subscription' do
    let(:event) { :downgraded_subscription }

    it 'enqueues SendEventToProfitwellJob' do
      service.call
      expect(SendEventToProfitwellJob)
        .to have_been_enqueued
        .with(event.to_s, params)
    end
  end
end
